//
//  LogTableViewController.swift
//  HXLogDemo
//
//  Created by HongXiangWen on 2019/9/2.
//  Copyright © 2019 WHX. All rights reserved.
//

import UIKit
import HXLog

class LogTableViewController: UITableViewController {

    private var logModels: [HXLogger.Model] = []
    private var count: Int = 0
    
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        return dateFormatter
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.didLogClosure = { [weak self] (model) in
            guard let `self` = self else { return }
            self.addLog(model: model)
        }
    }
    
    @IBAction func addLog(_ sender: Any) {
        addRandomLog()
    }
    
    @IBAction func shareLogs(_ sender: Any) {
        logger.shareLogFile(fromViewController: self)
    }
    
    private func addRandomLog() {
        guard let level = HXLogger.Level(rawValue: Int(arc4random() % 5)) else { return }
        switch level {
        case .verbose:
            logger.verbose("This is a verbose message! \(count + 1)")
        case .debug:
            logger.debug("This is a debug message! \(count + 1)")
        case .info:
            logger.info("This is an info message! \(count + 1)")
        case .warning:
            logger.warning("This is a warning message! \(count + 1)")
        case .error:
            logger.error("This is an error message \(count + 1)")
        }
        count += 1
    }
    
    private func addLog(model: HXLogger.Model) {
        logModels.append(model)
        tableView.insertRows(at: [IndexPath(row: logModels.count - 1, section: 0)], with: .none)
        if !tableView.isDragging {
            tableView.scrollToRow(at: IndexPath(row: logModels.count - 1, section: 0), at: .bottom, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logModels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LogTableViewCell") as! LogTableViewCell
        let log = logModels[indexPath.row]
        cell.timeLabel.text = dateFormatter.string(from: log.date)
        cell.logLabel.text = log.message
        switch log.level {
        case .verbose:
            cell.logLabel.textColor = .darkGray
        case .debug:
            cell.logLabel.textColor = .blue
        case .info:
            cell.logLabel.textColor = .black
        case .warning:
            cell.logLabel.textColor = .brown
        case .error:
            cell.logLabel.textColor = .red
        }
        return cell
    }
    
}
