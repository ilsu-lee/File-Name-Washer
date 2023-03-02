//
//  DropView.swift
//  File Name Washer
//
//  Copyright (C) 2023 ILSU LEE

//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or 3 any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

//import Foundation
import Cocoa

class DropView: NSView {

    
    
    var textField : NSTextField
    
    let TEXT_COLOR : NSColor = .black
    let TEXT_COLOR_ACTIVE : NSColor = NSColor(srgbRed: 0, green: 0, blue: 1, alpha: 1)
    
    let BG_COLOR : NSColor = .gray
    let BG_COLOR_ACTIVE : NSColor = NSColor(srgbRed: 0.3, green: 0.3, blue: 1, alpha: 1)
    
    required init?(coder: NSCoder) {
        self.textField = NSTextField.init()
        
        super.init(coder: coder)
        
        let width = 200.0
        let height = 100.0
        
        
        let x = (self.bounds.width - width) * 0.5
        let y = (self.bounds.height - height) * 0.5 - 20
        let f = CGRect(x: x, y: y, width: width, height: height)
        //let subview = NSView(frame: f)
        //subview.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin ]
        
        
        self.textField.frame = f
        
        self.textField.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin ]
        self.textField.stringValue = "Drop Here".localized
        self.textField.alignment = .center
        self.textField.font = NSFont.systemFont(ofSize: 30)
        self.textField.textColor = TEXT_COLOR
        
        self.textField.isBezeled = false
        self.textField.isEditable = false
        self.textField.drawsBackground = false
        
        self.wantsLayer = true
        self.layer?.backgroundColor = BG_COLOR.cgColor
//        self.layer?.backgroundColor = NSColor.clear.cgColor
        self.addSubview(self.textField)
        registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL])
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if checkExtension(sender) == true {
            self.layer?.backgroundColor = BG_COLOR_ACTIVE.cgColor
            self.textField.textColor = TEXT_COLOR_ACTIVE
            return .copy
        } else {
            return NSDragOperation()
        }
    }
    
//    fileprivate func checkExtension(_ drag: NSDraggingInfo) -> Bool {
//        guard let board = drag.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
//              let path = board[0] as? String
//        else { return false }
//
//        let suffix = URL(fileURLWithPath: path).pathExtension
//        for ext in self.expectedExt {
//            if ext.lowercased() == suffix {
//                return true
//            }
//        }
//        return false
//    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.layer?.backgroundColor = BG_COLOR.cgColor
        self.textField.textColor = TEXT_COLOR
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.layer?.backgroundColor = BG_COLOR.cgColor
        self.textField.textColor = TEXT_COLOR
    }
    
    
    func getParentPath(_ path : String) -> String {
        let fileURL: URL = URL(fileURLWithPath: path)
        let folderURL = fileURL.deletingLastPathComponent()
        return folderURL.path
    }
    
    

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? Array<String>
        else { return false }
        
        let firstItemPath = pasteboard[0]
        
        if let scriptPath = Bundle.main.path(forResource: "RenameScript", ofType: "sh") as? String {
            
            if(UserDefaults.standard.bool(forKey: "overwrite") ) {
                var hasFile = false
                for path in pasteboard {
                    if(!isDir(path)) {
                        hasFile = true
                        break
                    }
                }
                
                if hasFile {
                    let res = showAlert("When overwriting, you can select only directory.".localized, "", "Confirm".localized)
                    if(res == NSApplication.ModalResponse.alertFirstButtonReturn) {
                        return true
                    }
                }

                var scanCnt = 0
                for path in pasteboard {
                    scanCnt += dryRunRename(path: path)
                }
                    
                if scanCnt > 0 {
                    let res = showAlert(String(format:"%d files can be converted. Do you want to convert it?".localized, scanCnt), "", "Confirm".localized, "Cancel".localized)
                    
                    if (res == NSApplication.ModalResponse.alertFirstButtonReturn) {
                        var totalCnt = 0
                        for path in pasteboard {
                            totalCnt += runRename(path: path)
                        }
                    } else {
                        return true
                    }
                } else {
                    let res = showAlert("No convertible files were found.".localized, "", "Confirm".localized)
                    return true
                }
                
                
            } else {
                do {
                    let fileManager = FileManager.default
                    let appDirURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let tmpDirURL =  appDirURL.appendingPathComponent("tmp")
                    
                    try? fileManager.removeItem(atPath: tmpDirURL.path)
                    try fileManager.createDirectory(at: tmpDirURL, withIntermediateDirectories: false)
                                    
                    for path in pasteboard {
                        runCommand(launchPath: "/bin/cp", args: "-R", path, "\(tmpDirURL.path)/")
                    }
                    
                    let fileCnt = dryRunRename(path: tmpDirURL.path)
                    
                    if fileCnt > 0 {
                        let alert = showAlert(String(format:"%d files can be converted. Do you want to convert it?".localized, fileCnt), "", "Confirm".localized, "Cancel".localized)
                        if(alert == NSApplication.ModalResponse.alertFirstButtonReturn) {
    //                        getDestAndCopy(getParentPath(firstItemPath), scriptPath, "\(tmpDirURL.path)/", pasteboard)
                            getDestAndCopy(getParentPath(firstItemPath), scriptPath, tmpDirURL.path)
                        }
                    } else {
                        showAlert("No convertible files were found.".localized, "", "OK")
                    }
                    
                    try fileManager.removeItem(atPath: tmpDirURL.path)
                }catch {
                    print(error)
                }
            }
            
            
        } else {
            print("error")
        }
        return true
    }
    
    

    
    fileprivate func checkExtension(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    
    func copyToDest(destination : String, directoryPath : String, scriptPath : String, fromPath : String) {
        
    //        let result00 = runCommand(launchPath: "/bin/ls", args: "-d", destination)
    //        if result00.exitCode == 0 {
        if isDir(destination) {
            let res = showAlert("The targeted file already exists. Do you want to overwrite it?".localized, "", "Confirm".localized, "Cancel".localized)
            if(res == NSApplication.ModalResponse.alertSecondButtonReturn) {
                getDestAndCopy(directoryPath, scriptPath, fromPath)
                return
            }
        }
        
        runCommand(launchPath: "/usr/bin/perl", args: scriptPath, "-r", "-f", "utf8", "-t", "utf8", "--nfc", "--notest", fromPath)
        //copy to destination
        
        runCommand(launchPath: "/bin/cp",args: "-R", "\(fromPath)/", destination)
    }


    func getDestAndCopy(_ directoryPath : String, _ scriptPath : String, _ fromPath : String) {
        
        //get destination from user
        let openPanel = NSOpenPanel()
        openPanel.directoryURL = URL(fileURLWithPath: directoryPath)
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        
        let response = openPanel.runModal()

        if (response == .OK) {
            if let loadURL = openPanel.url {
                let destination = "\(loadURL.path)/\(UserDefaults.standard.string(forKey: "path")!)"
                copyToDest(destination: destination, directoryPath: directoryPath, scriptPath: scriptPath, fromPath: fromPath)
            }
        }
        
    }


    func showAlert(_ messageText : String, _ informativeText : String, _ buttonTitles : String...) -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.messageText = messageText
        alert.informativeText = informativeText
        
        for buttonTitle in buttonTitles {
            alert.addButton(withTitle: buttonTitle)
        }

        return alert.runModal()
    }

}
