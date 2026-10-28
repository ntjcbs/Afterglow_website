// Builds the generated parts of the website from the app's repository:
//
//   privacy.html   from PRIVACY.md, the same text the app shows in About Afterglow
//   images/icon-*  the app icon as macOS draws it, from Support/AppIcon.icon
//   images/*.jpg   web-sized copies of the store screenshots in dist/AppStoreMedia
//
// index.html, support.html and style.css are written by hand. Run from this
// repository's root after changing the policy, the icon or the screenshots:
//   swift scripts/make-site.swift [path to the Afterglow repository]
// The app's repository defaults to ../Afterglow, beside this one.
import AppKit

let site = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let root = CommandLine.arguments.count > 1 ? URL(fileURLWithPath: CommandLine.arguments[1])
    : site.deletingLastPathComponent().appendingPathComponent("Afterglow")
guard FileManager.default.fileExists(atPath: root.appendingPathComponent("PRIVACY.md").path) else {
    fatalError("No PRIVACY.md in \(root.path): pass the Afterglow repository's path.")
}
let images = site.appendingPathComponent("images")
try FileManager.default.createDirectory(at: images, withIntermediateDirectories: true)

// MARK: Privacy policy

func escape(_ text: String) -> String {
    text.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
}
/// PRIVACY.md uses only paragraphs, **bold** and [links](url).
func inline(_ text: String) -> String {
    var html = escape(text)
    html = html.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
    html = html.replacingOccurrences(of: #"\[([^\]]+)\]\(([^)]+)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)
    return html
}
let markdown = try String(contentsOf: root.appendingPathComponent("PRIVACY.md"), encoding: .utf8)
let paragraphs = markdown.components(separatedBy: "\n\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
var body: [String] = []
for (index, paragraph) in paragraphs.enumerated() {
    // A paragraph that is all bold is a heading: the first is the title.
    if paragraph.hasPrefix("**"), paragraph.hasSuffix("**"), !paragraph.dropFirst(2).dropLast(2).contains("**") {
        let title = escape(String(paragraph.dropFirst(2).dropLast(2)))
        body.append(index == 0 ? "<h1>\(title)</h1>" : "<h2>\(title)</h2>")
    } else if index == 1 {
        body.append("<p class=\"lede\">\(inline(paragraph))</p>")
    } else {
        body.append("<p>\(inline(paragraph))</p>")
    }
}
let privacy = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Afterglow Privacy Policy</title>
  <meta name="description" content="Afterglow Music Visualizer collects nothing: no accounts, no analytics, no advertising and no tracking.">
  <link rel="canonical" href="https://afterglowvisualizer.com/privacy.html">
  <link rel="icon" href="images/icon-64.png">
  <link rel="apple-touch-icon" href="images/icon-180.png">
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <!-- Generated from the app repository's PRIVACY.md by scripts/make-site.swift; edit that file instead. -->
  <header class="top">
    <div class="wrap">
      <a class="brand" href="./"><img src="images/icon-64.png" alt="">Afterglow</a>
      <nav><a href="support.html">Support</a><a href="privacy.html" aria-current="page">Privacy</a></nav>
    </div>
  </header>

  <main class="page">
    \(body.joined(separator: "\n    "))
  </main>

  <footer class="bottom">
    <div class="wrap">
      <span>© 2026 Nate Jacobs</span>
      <nav><a href="support.html">Support</a><a href="privacy.html">Privacy Policy</a></nav>
    </div>
  </footer>
</body>
</html>

"""
try privacy.write(to: site.appendingPathComponent("privacy.html"), atomically: true, encoding: .utf8)
print("Wrote privacy.html")

// MARK: Icon

// Compile the Icon Composer icon into a throwaway bundle and let macOS draw
// it, so the page shows exactly what Finder and the Dock show.
let scratch = FileManager.default.temporaryDirectory.appendingPathComponent("afterglow-site-\(UUID().uuidString)")
let bundle = scratch.appendingPathComponent("Icon.app/Contents")
try FileManager.default.createDirectory(at: bundle.appendingPathComponent("Resources"), withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: scratch) }
let actool = Process()
actool.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
actool.arguments = ["actool", root.appendingPathComponent("Support/AppIcon.icon").path, "--compile", bundle.appendingPathComponent("Resources").path,
                    "--platform", "macosx", "--minimum-deployment-target", "14.2", "--app-icon", "AppIcon",
                    "--output-partial-info-plist", scratch.appendingPathComponent("partial.plist").path]
actool.standardOutput = FileHandle.nullDevice
try actool.run()
actool.waitUntilExit()
guard actool.terminationStatus == 0 else { fatalError("actool could not compile Support/AppIcon.icon") }
// A bundle without a program is drawn crossed out, as an app that can't run.
try FileManager.default.createDirectory(at: bundle.appendingPathComponent("MacOS"), withIntermediateDirectories: true)
try FileManager.default.copyItem(at: URL(fileURLWithPath: "/usr/bin/true"), to: bundle.appendingPathComponent("MacOS/Icon"))
let info: [String: Any] = ["CFBundleIdentifier": "app.afterglow.site-icon-\(UUID().uuidString)", "CFBundlePackageType": "APPL",
                           "CFBundleExecutable": "Icon", "CFBundleIconFile": "AppIcon", "CFBundleIconName": "AppIcon"]
try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0).write(to: bundle.appendingPathComponent("Info.plist"))
let icon = NSWorkspace.shared.icon(forFile: scratch.appendingPathComponent("Icon.app").path)

func png(_ image: NSImage, size: Int, to url: URL) throws {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: url)
}
for size in [64, 180, 512] {
    try png(icon, size: size, to: images.appendingPathComponent("icon-\(size).png"))
}
print("Wrote images/icon-64.png, icon-180.png and icon-512.png")

// MARK: Screenshots

// Store name (without its number) → name on the site. The hero is the one
// that shows the app's own controls.
let screenshots = ["2-watch-it-glow": "hero", "5-play-anything": "play-anything", "3-big-screen": "big-screen",
                   "4-move-to-the-groove": "move-to-the-groove", "8-forty-thousand-looks": "forty-thousand-looks"]
let media = root.appendingPathComponent("dist/AppStoreMedia/screenshots")
for (source, name) in screenshots.sorted(by: { $0.key < $1.key }) {
    let input = media.appendingPathComponent("\(source).png")
    guard FileManager.default.fileExists(atPath: input.path) else {
        print("Missing \(input.path): run zsh Scripts/make-store-media.sh in the app's repository first. Kept the existing images/\(name).jpg.")
        continue
    }
    let sips = Process()
    sips.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    sips.arguments = ["-Z", "1600", "-s", "format", "jpeg", "-s", "formatOptions", "82", input.path,
                      "--out", images.appendingPathComponent("\(name).jpg").path]
    sips.standardOutput = FileHandle.nullDevice
    try sips.run()
    sips.waitUntilExit()
}
print("Wrote images/" + screenshots.values.sorted().map { "\($0).jpg" }.joined(separator: ", "))

// GitHub Pages: serve the files as they are, at the site's own domain.
try Data().write(to: site.appendingPathComponent(".nojekyll"))
