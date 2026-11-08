import AppKit
import SwiftUI

let app = NSApplication.shared
let view = ThumbnailView(frame: NSRect(x: 0, y: 0, width: 200, height: 130))
var copies = 0
var previews = 0
view.onCopy = { copies += 1 }
view.onPreview = { previews += 1 }
func mouse(_ type: NSEvent.EventType, flags: NSEvent.ModifierFlags, clicks: Int = 1) -> NSEvent {
    NSEvent.mouseEvent(with: type, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: 0,
                      context: nil, eventNumber: 1, clickCount: clicks, pressure: 1)!
}
view.mouseDown(with: mouse(.leftMouseDown, flags: .control))
assert(copies == 1 && previews == 0, "Control left click copies directly")
view.rightMouseDown(with: mouse(.rightMouseDown, flags: .control))
assert(copies == 2, "macOS routed Control right click copies directly")
view.mouseDown(with: mouse(.leftMouseDown, flags: [], clicks: 2))
assert(previews == 1, "double click previews")
assert(view.accessibilityPerformPress())
assert(previews == 2, "VoiceOver press previews")
let keyboard = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command,
    timestamp: 0, windowNumber: 0, context: nil, characters: "c", charactersIgnoringModifiers: "c", isARepeat: false, keyCode: 8)!
view.keyDown(with: keyboard)
assert(copies == 3, "Command C from focused thumbnail copies")
let icon = NSImage(contentsOfFile: CommandLine.arguments[1])
assert(icon != nil && icon!.representations.count > 0, "packaged ICNS is readable by AppKit")
print("PASS: Control click (both event routes), double click, keyboard copy, accessibility, packaged icon")

final class IncomingImageDrag: NSObject, NSDraggingInfo {
    var draggingDestinationWindow: NSWindow? { nil }
    var draggingSourceOperationMask: NSDragOperation { .copy }
    var draggingLocation: NSPoint { NSPoint(x: 100, y: 100) }
    var draggedImageLocation: NSPoint { .zero }
    var draggedImage: NSImage? { nil }
    let draggingPasteboard = NSPasteboard(name: NSPasteboard.Name("Hippocampus.DropRegression.\(UUID())"))
    var draggingSource: Any? { nil }
    var draggingSequenceNumber: Int { 1 }
    var draggingFormation: NSDraggingFormation = .none
    var animatesToDestination = false
    var numberOfValidItemsForDrop = 1
    var springLoadingHighlight: NSSpringLoadingHighlight { .none }
    func slideDraggedImage(to screenPoint: NSPoint) {}
    override func namesOfPromisedFilesDropped(atDestination dropDestination: URL) -> [String]? { nil }
    func resetSpringLoading() {}
    func enumerateDraggingItems(options: NSDraggingItemEnumerationOptions, for view: NSView?, classes: [AnyClass],
        searchOptions: [NSPasteboard.ReadingOptionKey: Any], using block: (NSDraggingItem, Int, UnsafeMutablePointer<ObjCBool>) -> Void) {}
}

let model = HippocampusModel()
let mainGallery = ExportOnlyHostingView(rootView: GalleryView(model: model, compact: false))
let quickController = galleryController(model: model, compact: true)
let quickGallery = quickController.view as! ExportOnlyHostingView<GalleryView>
let incoming = IncomingImageDrag()
incoming.draggingPasteboard.writeObjects([URL(fileURLWithPath: "/tmp/incoming-photo.png") as NSURL])
for gallery in [mainGallery, quickGallery] {
    assert(gallery.draggingEntered(incoming).isEmpty, "incoming files are rejected at entry")
    assert(gallery.draggingUpdated(incoming).isEmpty, "incoming files stay rejected when moving")
    assert(!gallery.prepareForDragOperation(incoming), "incoming drop cannot be prepared")
    assert(!gallery.performDragOperation(incoming), "incoming drop cannot import a photo")
}
assert(model.captures.isEmpty, "rejected drops do not enter the library")
print("PASS: large gallery and menu panel reject incoming image drops at every drop phase")
