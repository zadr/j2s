import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var input: NSTextView!
    @IBOutlet weak var output: NSTextView!
    @IBOutlet weak var prettyPrint: NSButton!
    @IBOutlet weak var rootName: NSTextField!
    @IBOutlet weak var filePerStruct: NSButton!
    @IBOutlet weak var save: NSButton!
}

extension AppDelegate: NSTextFieldDelegate, NSTextViewDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        input.isAutomaticQuoteSubstitutionEnabled = false
        output.isAutomaticQuoteSubstitutionEnabled = false

        textDidChange()

        prettyPrint.target = self
        prettyPrint.action = #selector(prettyPrintDidChange(_:))

        save.target = self
        save.action = #selector(saveDocument(_:))
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        open(URL(fileURLWithPath: filename))

        return true
    }

    override func controlTextDidChange(_ obj: Notification) {
        textDidChange()
    }

    func textDidChange(_ notification: Notification) {
        textDidChange()
    }

    func textDidChange() {
        let data = input.string!.data(using: .utf8)!
        do {
            let parsed = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

            if prettyPrint.state == NSOnState {
                let pretty = try JSONSerialization.data(withJSONObject: parsed, options: .prettyPrinted)
                let string = String(data: pretty, encoding: .utf8)
                input.string = string ?? ""
            }

            if let dictionary = parsed as? [String: Any] {
                let structs = structify(name: rootElementName(), json: dictionary)
                output.string = structs.map({ return $0.description }).joined(separator: "\n\n// MARK: -\n\n") + "\n"
            }
        } catch let exception {
            if data.isEmpty {
                output.string = ""
            } else {
                print(exception)
            }
        }
    }

    @IBAction public func prettyPrintDidChange(_ sender: Any) {
        textDidChange()
    }

    @IBAction public func openDocument(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canCreateDirectories = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = [ "json", "js" ]
        openPanel.allowsMultipleSelection = false
        openPanel.beginSheetModal(for: window) { choice in
            if choice == NSFileHandlingPanelOKButton, let url = openPanel.url {
                self.open(url)
            }
        }
    }

    @IBAction public func saveDocument(_ sender: Any) {
        let data = input.string!.data(using: .utf8)!
        do {
            let parsed = try JSONSerialization.jsonObject(with: data, options: .allowFragments)

            if let dictionary = parsed as? [String: Any] {
                let structs = structify(name: rootElementName(), json: dictionary)

                if !structs.isEmpty {
                    if filePerStruct.state == NSOnState {
                        let savePanel = NSOpenPanel()
                        savePanel.canCreateDirectories = true
                        savePanel.canChooseDirectories = true
                        savePanel.canChooseFiles = false
                        savePanel.prompt = "Save"

                        savePanel.beginSheetModal(for: window) { choice in
                            if choice == NSFileHandlingPanelOKButton, let url = savePanel.directoryURL {
                                structs.forEach {
                                    let url = url.appendingPathComponent($0.name.generatedClassName()).appendingPathExtension("swift")
                                    return try! $0.description.write(to: url, atomically: true, encoding: .utf8)
                                }
                            }
                        }
                    } else {
                        let savePanel = NSSavePanel()
                        savePanel.canCreateDirectories = true
                        savePanel.allowedFileTypes = [ "swift" ]
                        savePanel.nameFieldStringValue = "Models.swift"

                        savePanel.beginSheetModal(for: window) { choice in
                            if choice == NSFileHandlingPanelOKButton, let url = savePanel.url {
                                try! self.output.string!.write(to: url, atomically: true, encoding: .utf8)
                            }
                        }
                    }
                }
            }
        } catch let exception {
            print(exception)
        }
    }
}

extension AppDelegate {
    fileprivate func rootElementName() -> String {
        return rootName.stringValue.isEmpty ? "Root" : rootName.stringValue
    }
    fileprivate func open(_ url: URL) {
        do {
            if self.prettyPrint.state == NSOnState {
                let stream = InputStream(url: url)!
                stream.open()

                let parsed = try JSONSerialization.jsonObject(with: stream, options: .allowFragments)
                let pretty = try JSONSerialization.data(withJSONObject: parsed, options: .prettyPrinted)
                let string = String(data: pretty, encoding: .utf8)
                self.input.string = string ?? ""
            } else {
                self.input.string = try String(contentsOf: url)
            }

            self.textDidChange()

            NSDocumentController.shared().noteNewRecentDocumentURL(url)
        } catch let exception {
            print(exception)
        }
    }
}

