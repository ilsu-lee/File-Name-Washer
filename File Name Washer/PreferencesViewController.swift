//
//  PreferencesViewController.swift
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

import Foundation


import Cocoa

class PreferencesViewController: NSViewController {
    
    let TEXT_COLOR_INACTIVE : NSColor = NSColor(srgbRed: 0.6, green: 0.6, blue: 0.6, alpha: 1)
    let TEXT_COLOR_ACTIVE : NSColor = NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 1)

    @IBOutlet weak var checkOverwrite: NSButton!
    
    @IBOutlet weak var textFieldPath: NSTextField!
    
    @IBOutlet weak var labelPath: NSTextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let defaults = UserDefaults.standard
        
        checkOverwrite.state = defaults.bool(forKey: "overwrite") ? .on : .off
        textFieldPath.stringValue = defaults.string(forKey: "path") ?? ""
        
        handleLabelArea()
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func clickConfirm(_ sender: Any) {
        let defaults = UserDefaults.standard
        
        defaults.set(checkOverwrite.state == .on , forKey: "overwrite")
        
        if self.checkOverwrite.state == .off {
            defaults.set(textFieldPath.stringValue , forKey: "path")
        }
        
        self.view.window?.close()
    }
    
    @IBAction func clickCancel(_ sender: Any) {
        self.view.window?.close()
    }
    
    
    @IBAction func clickCheck(_ sender: NSButton) {
        handleLabelArea()
    }
    
    func handleLabelArea() {
        if(checkOverwrite.state == .on) {
            textFieldPath.isEditable = false
            textFieldPath.isEnabled = false
            labelPath.textColor = TEXT_COLOR_INACTIVE
        } else {
            textFieldPath.isEditable = true
            textFieldPath.isEnabled = true
            labelPath.textColor = TEXT_COLOR_ACTIVE
        }
    }
}





