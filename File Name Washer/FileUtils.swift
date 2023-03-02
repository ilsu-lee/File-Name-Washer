//
//  FileUtils.swift
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

let PATTERN_DRY_RUN_RESULT = "Would have converted (\\d+) files in \\d+ seconds."
let PATTERN_RUN_RESULT = "Ready! I converted (\\d+) files in \\d+ seconds."

func runCommand(launchPath : String, args : String...) -> (stdout: String, stderr: String, exitCode: Int32) {
    let task = Process()
    task.launchPath = launchPath
    task.arguments = args
    
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    task.standardOutput = outputPipe
    task.standardError = errorPipe
    let outputHandle = outputPipe.fileHandleForReading
    outputHandle.waitForDataInBackgroundAndNotify()
    
    let errorHandle = errorPipe.fileHandleForReading
    errorHandle.waitForDataInBackgroundAndNotify()

    var stdout = ""
    var stderr = ""
    outputHandle.readabilityHandler = { pipe in
        guard let currentOutput = String(data: pipe.availableData, encoding: .utf8) else {
            print("Error decoding data: \(pipe.availableData)")
            return
        }
        guard !currentOutput.isEmpty else {
            return
        }
        stdout = stdout + currentOutput + "\n"
    }
    
    
    errorHandle.readabilityHandler = { pipe in
        guard let currentOutput = String(data: pipe.availableData, encoding: .utf8) else {
            print("Error decoding data: \(pipe.availableData)")
            return
        }
        guard !currentOutput.isEmpty else {
            return
        }
        stderr = stderr + currentOutput + "\n"
    }
    
    task.launch()
    task.waitUntilExit()
    
    return (stdout, stderr, task.terminationStatus)
}


func findRegText(input : String, pattern : String) -> String?{
    do {
        let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
        let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
        
        if let match = matches.first {
            let range = match.range(at:1)
            if let swiftRange = Range(range, in: input) {
                return String(input[swiftRange])
            }
        }
        return nil
    } catch {
        return nil
    }
}

func getFileNameInPath(_ path : String) -> String{
    return URL(fileURLWithPath: path).lastPathComponent
}


func dryRunRename (path : String) -> Int {
    if let scriptPath = Bundle.main.path(forResource: "RenameScript", ofType: "sh") {
        var scanCnt = 0
        let dryRunResult = runCommand(launchPath: "/usr/bin/perl", args: scriptPath, "-r", "-f", "utf8", "-t", "utf8", "--nfc", path)
        if let fileCnt = findRegText(input : dryRunResult.stderr, pattern : PATTERN_DRY_RUN_RESULT) {
            scanCnt += Int(fileCnt)!
        }
//            return scanCnt > 0 ? scanCnt-1 : scanCnt
        return scanCnt
    } else {
        return 0
    }
}


func runRename (path : String) -> Int {
    if let scriptPath = Bundle.main.path(forResource: "RenameScript", ofType: "sh") {
        var scanCnt = 0
        let dryRunResult = runCommand(launchPath: "/usr/bin/perl", args: scriptPath, "-r", "-f", "utf8", "-t", "utf8", "--nfc", "--notest", path)
        if let fileCnt = findRegText(input : dryRunResult.stderr, pattern : PATTERN_RUN_RESULT) {
            scanCnt += Int(fileCnt)!
        }
//            return scanCnt > 0 ? scanCnt-1 : scanCnt
        return scanCnt
    } else {
        return 0
    }
}


func isDir(_ path : String) -> Bool{
    if let scriptPath = Bundle.main.path(forResource: "IsDirectoryScript", ofType: "sh") as? String {
        let result = runCommand(launchPath: "/bin/bash" , args: scriptPath, path)
        return result.exitCode == 0
    } else {
        return false
    }
}


