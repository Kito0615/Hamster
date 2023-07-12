//
//  BackupViewController.swift
//  Hamster
//
//  Created by morse on 2023/6/14.
//

import Combine
import HamsterUIKit
import UIKit

protocol BackupViewModelFactory {
  func makeBackupViewModel() -> BackupViewModel
}

class BackupViewController: NibLessViewController {
  // MARK: properties

  private let backupViewModel: BackupViewModel
  private var subscriptions = Set<AnyCancellable>()

  // MARK: methods

  init(backupViewModelFactory: BackupViewModelFactory) {
    self.backupViewModel = backupViewModelFactory.makeBackupViewModel()
    super.init()

    backupViewModel.$backupSwipeAction
      .receive(on: DispatchQueue.main)
      .sink { [unowned self] action in
        guard let action = action else { return }
        swipeActionHandled(action: action)
      }.store(in: &subscriptions)
  }

  func swipeActionHandled(action: BackupSwipeAction) {
    switch action {
    case .delete:
      deleteBackupAction()
    case .rename:
      renameAction()
    }
  }

  func deleteBackupAction() {
    let alertController = UIAlertController(title: "是否删除？", message: "文件删除后无法恢复，确认删除？", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "确认", style: .destructive, handler: { [unowned self] _ in
      Task {
        guard let selectFile = backupViewModel.selectFile else { return }
        do {
          try self.backupViewModel.deleteBackupFile(selectFile.url)
        } catch {
          presentError(error: ErrorMessage(title: "删除文件", message: "删除失败"))
        }
        await self.backupViewModel.loadBackupFiles()
      }
    }))
    alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
    present(alertController, animated: true, completion: nil)
  }

  func renameAction() {
    let alertController = UIAlertController(title: "修改备份文件名称", message: nil, preferredStyle: .alert)
    alertController.addTextField { $0.placeholder = "新文件名称" }
    alertController.addAction(UIAlertAction(title: "确认", style: .destructive, handler: { [unowned self, alertController] _ in
      Task {
        guard let textFields = alertController.textFields else { return }
        guard let selectFile = backupViewModel.selectFile else { return }
        let newFileName = textFields[0].text ?? ""
        guard !newFileName.isEmpty else { return }
        try await self.backupViewModel.renameBackupFile(at: selectFile.url, newFileName: newFileName)
        await self.backupViewModel.loadBackupFiles()
      }
    }))
    alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
    present(alertController, animated: true)
  }
}

// MARK: override UIViewController

extension BackupViewController {
  override func loadView() {
    super.loadView()

    title = "备份与恢复"
    view = BackupRootView(backupViewModel: backupViewModel)
  }
}
