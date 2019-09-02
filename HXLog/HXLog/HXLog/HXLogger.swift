//
//  HXLogger.swift
//  HXLog
//
//  Created by HongXiangWen on 2019/8/23.
//  Copyright © 2019 WHX. All rights reserved.
//

import Foundation

/// 打印日志管理类
public class HXLogger: NSObject {
    
    /// 日志级别
    public enum Level: Int {
        
        case verbose = 0
        case debug
        case info
        case warning
        case error
        
        /// 日志等级名称
        var name: String {
            switch self {
            case .verbose:
                return "VERBOSE"
            case .debug:
                return "DEBUG"
            case .info:
                return "INFO"
            case .warning:
                return "WARNING"
            case .error:
                return "ERROR"
            }
        }
        
    }
    
    /// 日志最终输出选项
    public struct Destination: OptionSet {
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        /// 通过print输出到控制台
        public static let print = Destination(rawValue: 1 << 0)
        
        /// 通过NSLog输出到控制台
        public static let nslog = Destination(rawValue: 1 << 1)
        
        /// 保存到文件中
        public static let file = Destination(rawValue: 1 << 2)
        
        /// 既在控制台打印又保存到文件中
        public static let printAndFile: Destination = [.print, file]
        
        /// 既在控制台打印又保存到文件中
        public static let nslogAndFile: Destination = [.nslog, file]
        
    }
    
    /// 日志格式
    public struct Format: OptionSet {
        
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        /// 日期
        public static let date = Format(rawValue: 1 << 0)
        
        /// 日志级别
        public static let levelName = Format(rawValue: 1 << 1)

        /// 文件名
        public static let fileName = Format(rawValue: 1 << 2)

        /// 方法名
        public static let methodName = Format(rawValue: 1 << 3)

        /// 行数
        public static let line = Format(rawValue: 1 << 4)
        
        /// 当前线程名称
        public static let thread = Format(rawValue: 1 << 5)
        
        /// 所有的选项
        public static let all: Format = [.date, .levelName, .fileName, .methodName, .line, .thread]

        /// 默认选项
        public static let `default`: Format = [.date, .levelName, .fileName, .methodName, .line]
    }
    
    /// 日志模型
    public struct Model {
        
        /// 日期
        public var date: Date
        /// 原始日志
        public var message: String
        /// 格式化后的日志
        public var formatted: String
        /// 日志级别
        public var level: Level
        
    }

    // MARK: -  Public Properties
    
    /// 是否允许打印log，默认为true
    open var isLogEnabled = true
    
    /// 打印结束之后的回调（始终在主线程回调）
    open var didLogClosure: ((_ model: Model) -> ())?
    
    /// 最低打印日志级别，默认为.verbose
    open var minLevel: Level = .verbose
    
    /// 日期格式
    open var dateFormat: String = "yyyy-MM-dd HH:mm:ss.SSS" {
        didSet {
            dateFormatter.dateFormat = dateFormat
        }
    }
    
    /// 日志输出选项，默认为.printAndFile
    open var destination: Destination = .printAndFile

    /// 日志格式选项，默认为.default
    open var format: Format = .default
    
    /// 是否每次写入文件都同步，默认为false
    open var syncAfterEachWrite: Bool = false
    
    // MARK: -  Private Properties

    /// 保存文件的队列
    private var saveQueue: DispatchQueue = DispatchQueue(label: "com.whx.hxlog.savequeue", qos: .background)
    
    /// 文件管理器
    private let fileManager = FileManager.default
    
    /// 日志写入文件句柄
    private var fileHandle: FileHandle?
    
    /// 日志文件保存路径
    private var logFileURL: URL?
    
    /// 日期格式化
    private let dateFormatter = DateFormatter()

    // MARK: -  Initialize
    
    /// 单例对象
    public static let shared = HXLogger()
    private override init() {
        super.init()
        let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        logFileURL = url?.appendingPathComponent("HXLog.log", isDirectory: false)
        dateFormatter.dateFormat = dateFormat
    }
    
}

// MARK: - Public Methods
extension HXLogger {
    
    /// 打印日志
    ///
    /// - Parameters:
    ///   - message: 日志信息
    ///   - level: 日志级别
    ///   - currentTime: 日志时间
    ///   - filePath: 文件名
    ///   - methodName: 方法名
    ///   - line: 行数
    ///   - thread: 线程
    public func log<T>(_ message: T, level: Level, currentTime: Date, filePath: String, methodName: String, line: Int, thread: String) {
        /// 如果没打开日志或日志级别过低，则忽略
        guard isLogEnabled, level.rawValue >= minLevel.rawValue else { return }
        /// 组装日志
        var logText = ""
        if format.contains(.date) {
            logText += dateFormatter.string(from: currentTime) + " "
        }
        if format.contains(.levelName) {
            logText += "[\(level.name)]" + " "
        }
        if format.contains(.fileName) {
            let fileName = (filePath as NSString).lastPathComponent.components(separatedBy: ".").first!
            logText += "\(fileName)"
        }
        if format.contains(.methodName) {
            logText += ".\(methodName)"
        }
        if format.contains(.line) {
            logText += "[\(line)]"
        }
        if format.contains(.thread) {
            logText += "(\(thread))"
        }
        logText += ": \(message)"
        /// 输出日志
        if destination.contains(.print) {
            print(logText)
        }
        if destination.contains(.nslog) {
            NSLog(logText)
        }
        if destination.contains(.file) {
            /// 串行队列异步执行保存操作
            saveQueue.async {
                self.saveToFile(logText: logText)
            }
        }
        let model = Model(date: currentTime, message: "\(message)", formatted: logText, level: level)
        /// 主线程回调
        DispatchQueue.main.async {
            self.didLogClosure?(model)
        }
    }
    
    /// 打印verbose等级的日志
    public func verbose<T>(_ message: T, currentTime: Date = Date(), filePath: String = #file, methodName: String = #function, line: Int = #line, thread: Thread = Thread.current) {
        log(message, level: .verbose, currentTime: currentTime, filePath: filePath, methodName: methodName, line: line, thread: thread.description)
    }
    
    /// 打印info等级的日志
    public func info<T>(_ message: T, currentTime: Date = Date(), filePath: String = #file, methodName: String = #function, line: Int = #line, thread: Thread = Thread.current) {
        log(message, level: .info, currentTime: currentTime, filePath: filePath, methodName: methodName, line: line, thread: thread.description)
    }
    
    /// 打印debug等级的日志
    public func debug<T>(_ message: T, currentTime: Date = Date(), filePath: String = #file, methodName: String = #function, line: Int = #line, thread: Thread = Thread.current) {
        log(message, level: .debug, currentTime: currentTime, filePath: filePath, methodName: methodName, line: line, thread: thread.description)
    }
    
    /// 打印warning等级的日志
    public func warning<T>(_ message: T, currentTime: Date = Date(), filePath: String = #file, methodName: String = #function, line: Int = #line, thread: Thread = Thread.current) {
        log(message, level: .warning, currentTime: currentTime, filePath: filePath, methodName: methodName, line: line, thread: thread.description)
    }
    
    /// 打印error等级的日志
    public func error<T>(_ message: T, currentTime: Date = Date(), filePath: String = #file, methodName: String = #function, line: Int = #line, thread: Thread = Thread.current) {
        log(message, level: .error, currentTime: currentTime, filePath: filePath, methodName: methodName, line: line, thread: thread.description)
    }
    
    /// 保存日志到文件
    ///
    /// - Parameter logText: 日志
    /// - Returns: 是否保存成功
    @discardableResult
    public func saveToFile(logText: String) -> Bool {
        guard let url = logFileURL else { return false }
        do {
            if !fileManager.fileExists(atPath: url.path) {
                let line = logText + "\n"
                try line.write(to: url, atomically: true, encoding: .utf8)
            } else {
                if fileHandle == nil {
                    fileHandle = try FileHandle(forWritingTo: url)
                }
                if let fileHandle = fileHandle {
                    fileHandle.seekToEndOfFile()
                    let line = logText + "\n"
                    if let data = line.data(using: .utf8) {
                        fileHandle.write(data)
                        if syncAfterEachWrite {
                            fileHandle.synchronizeFile()
                        }
                    }
                }
            }
            return true
        } catch {
            print("Could not write to file \(url).")
            return false
        }
    }
    
    /// 删除日志文件
    ///
    /// - Returns: 是否删除成功
    @discardableResult
    public func deleteLogFile() -> Bool {
        guard let url = logFileURL, fileManager.fileExists(atPath: url.path) else { return true }
        do {
            try fileManager.removeItem(at: url)
            fileHandle = nil
            return true
        } catch {
            print("Could not remove file \(url).")
            return false
        }
    }

    /// 分享日志文件
    ///
    /// - Parameters:
    ///   - viewController: 当前视图控制器
    ///   - poroverSource: 当设备为iPad时，需要传入此参数
    ///   - completion: 分享结果回调
    public func shareLogFile(fromViewController viewController: UIViewController, poroverSource: Any? = nil, completion: UIActivityViewController.CompletionWithItemsHandler? = nil) {
        guard let url = logFileURL, fileManager.fileExists(atPath: url.path) else {
            print("There is no log file.")
            return
        }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        /// 兼容iPad
        let popover = activityVC.popoverPresentationController
        if (popover != nil) {
            if let sourceView = poroverSource as? UIView {
                popover!.sourceView = sourceView
            } else if let barButtonItem = poroverSource as? UIBarButtonItem {
                popover!.barButtonItem = barButtonItem
            }
            popover!.permittedArrowDirections = .any
        }
        /// 回调
        activityVC.completionWithItemsHandler = completion
        viewController.present(activityVC, animated: true, completion: nil)
    }
    
}
