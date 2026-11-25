// macOS native text renderer. Run: swift render_text.swift jobs.json output-dir
import AppKit
import CoreText
import ImageIO

struct TextRun: Codable {
    var text: String
    var x: Double
    var baseline: Double
    var size_pt: Double
    var weight: Double?
    var font_name: String?
    var color: [Double]?
    var kern_pt: Double?
}
struct Search: Codable {
    var reference_rgba: String
    var size_pt: [Double]?
    var weight: [Double]?
    var x: [Double]?
    var baseline: [Double]?
    var kern_pt: [Double?]?
}
struct Job: Codable {
    var name: String
    var width: Int
    var height: Int
    var scale: Double?
    var background: [Double]?
    var runs: [TextRun]
    var fit: Search?
    var replacement: String?
}
struct Input: Codable { var jobs: [Job] }
enum Failure: Error, CustomStringConvertible {
    case invalid(String)
    var description: String { if case .invalid(let s) = self { return s }; return "Invalid input" }
}

func color(_ values: [Double]) throws -> CGColor {
    guard [3, 4].contains(values.count), values.allSatisfy({ $0.isFinite && $0 >= 0 && $0 <= 255 }) else {
        throw Failure.invalid("Colors must contain 3 or 4 channel values between 0 and 255")
    }
    return CGColor(colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, components: [values[0]/255,values[1]/255,values[2]/255,(values.count == 4 ? values[3] : 255)/255])!
}

func render(_ job: Job) throws -> CGContext {
    let scale = job.scale ?? 1
    guard job.width > 0, job.height > 0, scale.isFinite, scale > 0 else {
        throw Failure.invalid("Canvas dimensions and scale must be positive")
    }
    guard let ctx = CGContext(data:nil,width:job.width,height:job.height,bitsPerComponent:8,bytesPerRow:job.width*4,space:CGColorSpace(name:CGColorSpace.sRGB)!,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else {
        throw Failure.invalid("Cannot allocate canvas")
    }
    ctx.setFillColor(try color(job.background ?? [255,255,255,255]))
    ctx.fill(CGRect(x:0,y:0,width:job.width,height:job.height))
    ctx.setAllowsFontSmoothing(false)
    ctx.setShouldSmoothFonts(false)
    ctx.setShouldAntialias(true)
    ctx.setAllowsFontSubpixelPositioning(true)
    ctx.setShouldSubpixelPositionFonts(true)
    ctx.scaleBy(x:scale,y:scale)
    for run in job.runs {
        let line = try makeLine(run)
        ctx.textPosition = CGPoint(x:run.x/scale,y:(Double(job.height)-run.baseline)/scale)
        CTLineDraw(line,ctx)
    }
    return ctx
}

func makeLine(_ run: TextRun) throws -> CTLine {
    guard run.size_pt.isFinite, run.size_pt > 0, run.x.isFinite, run.baseline.isFinite,
          (run.weight ?? 0).isFinite, run.kern_pt?.isFinite ?? true,
          !run.text.contains("\n"), !run.text.contains("\r") else {
        throw Failure.invalid("Each run must be a finite, positive-sized single line")
    }
    let font: NSFont
    if let name = run.font_name {
        guard let named = NSFont(name:name,size:run.size_pt) else {
            throw Failure.invalid("Requested font is unavailable: \(name)")
        }
        font = named
    } else {
        font = NSFont.systemFont(ofSize:run.size_pt,weight:NSFont.Weight(rawValue:run.weight ?? 0))
    }
    let c = try color(run.color ?? [0,0,0,255])
    var attrs: [NSAttributedString.Key:Any] = [.font:font,.foregroundColor:NSColor(cgColor:c)!]
    if let kern = run.kern_pt { attrs[.kern] = kern }
    return CTLineCreateWithAttributedString(NSAttributedString(string:run.text,attributes:attrs))
}

func bytes(_ ctx: CGContext, _ job: Job) -> [UInt8] {
    Array(UnsafeBufferPointer(start:ctx.data!.assumingMemoryBound(to:UInt8.self),count:job.width*job.height*4))
}

func errorMetrics(_ candidate:[UInt8],_ target:[UInt8]) -> (squared:Double,different:Int,maximum:Int) {
    var squared=0.0, different=0, maximum=0
    for i in stride(from:0,to:candidate.count,by:4) {
        var pixelDifferent=false
        for channel in 0..<4 {
            let delta=abs(Int(candidate[i+channel])-Int(target[i+channel]))
            squared += Double(delta*delta)
            maximum=max(maximum,delta)
            pixelDifferent = pixelDifferent || delta != 0
        }
        if pixelDifferent { different += 1 }
    }
    return (squared,different,maximum)
}

func fit(_ job:Job, _ search:Search, _ configDirectory:URL) throws -> (Job,[String:Any]) {
    guard job.runs.count == 1 else { throw Failure.invalid("Fit uses one representative text run; render multiple positioned runs separately") }
    let background=job.background ?? [255,255,255,255]
    guard background.count == 3 || (background.count == 4 && background[3] == 255) else { throw Failure.invalid("Raw RGBA fitting currently requires an opaque background") }
    let target=Array(try Data(contentsOf:configDirectory.appendingPathComponent(search.reference_rgba)))
    guard target.count == job.width*job.height*4, stride(from:3,to:target.count,by:4).allSatisfy({target[$0] == 255}) else {
        throw Failure.invalid("Reference RGBA must have matching canvas dimensions and opaque pixels")
    }
    let run=job.runs[0]
    let sizes=search.size_pt ?? [run.size_pt], weights=search.weight ?? [run.weight ?? 0]
    let xs=search.x ?? [run.x], baselines=search.baseline ?? [run.baseline]
    let kerns=search.kern_pt ?? [run.kern_pt]
    guard !sizes.isEmpty && !weights.isEmpty && !xs.isEmpty && !baselines.isEmpty && !kerns.isEmpty else {
        throw Failure.invalid("Search axes cannot be empty")
    }
    let combinations=Double(sizes.count)*Double(weights.count)*Double(xs.count)*Double(baselines.count)*Double(kerns.count)
    guard combinations <= 20000 else { throw Failure.invalid("Search exceeds 20000 candidates; narrow the axes or use successive passes") }
    var best=job
    var bestScore=Double.infinity
    var bestMetrics:(squared:Double,different:Int,maximum:Int)=(0,0,0)
    var evaluated=0
    for size in sizes { for weight in weights { for x in xs { for baseline in baselines { for kern in kerns {
        var candidate=job
        candidate.runs[0].size_pt=size;candidate.runs[0].weight=weight
        candidate.runs[0].x=x;candidate.runs[0].baseline=baseline;candidate.runs[0].kern_pt=kern
        let ctx=try render(candidate)
        let metrics=errorMetrics(bytes(ctx,candidate),target)
        evaluated += 1
        if metrics.squared < bestScore { best=candidate;bestScore=metrics.squared;bestMetrics=metrics }
    }}}}}
    return (best,["evaluated_candidates":evaluated,"compared_pixels":job.width*job.height,
        "different_pixels":bestMetrics.different,"exact":bestMetrics.different == 0,
        "maximum_channel_error":bestMetrics.maximum,
        "mean_squared_error_rgba":bestMetrics.squared/Double(target.count)])
}

func save(_ job:Job, _ output:URL) throws -> [String:Any] {
    let ctx=try render(job)
    guard let image=ctx.makeImage(),let dest=CGImageDestinationCreateWithURL(output as CFURL,"public.png" as CFString,1,nil) else {
        throw Failure.invalid("Cannot create PNG output")
    }
    CGImageDestinationAddImage(dest,image,nil)
    guard CGImageDestinationFinalize(dest) else { throw Failure.invalid("PNG output failed") }
    var descriptions:[[String:Any]]=[]
    for run in job.runs {
        let line=try makeLine(run)
        let scale=job.scale ?? 1
        let bounds=CTLineGetBoundsWithOptions(line,.useGlyphPathBounds)
        let pixelBounds=CGRect(x:run.x+bounds.minX*scale,y:run.baseline-bounds.maxY*scale,width:bounds.width*scale,height:bounds.height*scale)
        let fonts=(CTLineGetGlyphRuns(line) as! [CTRun]).map { glyphRun -> String in
            let attrs=CTRunGetAttributes(glyphRun) as NSDictionary
            return CTFontCopyPostScriptName(attrs[kCTFontAttributeName] as! CTFont) as String
        }
        let glyphRuns=CTLineGetGlyphRuns(line) as! [CTRun]
        let missing=glyphRuns.reduce(0) { count,glyphRun in
            var glyphs=[CGGlyph](repeating:0,count:CTRunGetGlyphCount(glyphRun))
            CTRunGetGlyphs(glyphRun,CFRange(location:0,length:0),&glyphs)
            return count+glyphs.filter{$0 == 0}.count
        }
        let encoded=try JSONSerialization.jsonObject(with:JSONEncoder().encode(run))
        descriptions.append(["parameters":encoded,"actual_run_fonts":fonts,"missing_glyphs":missing,
            "typographic_width_px":CTLineGetTypographicBounds(line,nil,nil,nil)*scale,
            "glyph_bounds_px":[pixelBounds.minX,pixelBounds.minY,pixelBounds.maxX,pixelBounds.maxY],
            "glyph_bounds_inside_canvas":CGRect(x:0,y:0,width:job.width,height:job.height).contains(pixelBounds)])
    }
    return ["output":output.path,"size":[job.width,job.height],"scale":job.scale ?? 1,"runs":descriptions]
}

do {
    guard CommandLine.arguments.count == 3 else { throw Failure.invalid("Usage: swift render_text.swift jobs.json output-directory") }
    let configURL=URL(fileURLWithPath:CommandLine.arguments[1]).standardizedFileURL
    let destination=URL(fileURLWithPath:CommandLine.arguments[2]).standardizedFileURL
    let input=try JSONDecoder().decode(Input.self,from:Data(contentsOf:configURL))
    try FileManager.default.createDirectory(at:destination,withIntermediateDirectories:true)
    var names=Set<String>()
    for job in input.jobs {
        guard job.name.range(of:"^[A-Za-z0-9][A-Za-z0-9_-]*$",options:.regularExpression) != nil else { throw Failure.invalid("Use a simple filename for job names") }
        let outputs=[job.name]+(job.replacement == nil ? [] : [job.name+"-replacement"])
        for name in outputs { guard names.insert(name).inserted else { throw Failure.invalid("Duplicate output name: \(name)") } }
    }
    var report:[[String:Any]]=[]
    for job in input.jobs {
        var matched=job
        var fitReport:[String:Any]?
        if let search=job.fit { (matched,fitReport)=try fit(job,search,configURL.deletingLastPathComponent()) }
        var entry=try save(matched,destination.appendingPathComponent(job.name+".png"))
        if let fitReport=fitReport { entry["calibration"]=fitReport }
        if let replacement=job.replacement {
            guard matched.runs.count == 1 else { throw Failure.invalid("Replacement requires one run; use separate jobs for multi-run layout") }
            var changed=matched;changed.runs[0].text=replacement
            entry["replacement"]=try save(changed,destination.appendingPathComponent(job.name+"-replacement.png"))
        }
        report.append(entry)
    }
    let data=try JSONSerialization.data(withJSONObject:report,options:[.prettyPrinted,.sortedKeys])
    try data.write(to:destination.appendingPathComponent("render-report.json"))
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))
} catch {
    FileHandle.standardError.write(Data("error: \(error)\n".utf8))
    exit(2)
}
