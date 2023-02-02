//
//  SystemKeyboardView.swift
//  HamsterKeyboard
//
//  Created by morse on 10/1/2023.
//

import KeyboardKit
import Plist
import SwiftUI

struct AlphabetKeyboard: View {
  var layoutProvider: KeyboardLayoutProvider
  var appearance: KeyboardAppearance
  var actionHandler: KeyboardActionHandler

  @EnvironmentObject
  private var context: KeyboardContext

  @EnvironmentObject
  private var autocompleteContext: AutocompleteContext

  @EnvironmentObject
  private var actionCalloutContext: ActionCalloutContext

  @EnvironmentObject
  private var inputCalloutContext: InputCalloutContext

  var skinExtend: [String: String] = [:]

  init(list: Plist) {
    if let dict = list.dict {
      for (key, value) in dict {
        if let value = value as? String {
          skinExtend[(key as! String).lowercased()] = value
        }
      }
    }
    let controller = KeyboardInputViewController.shared
    layoutProvider = controller.keyboardLayoutProvider
    appearance = controller.keyboardAppearance
    actionHandler = controller.keyboardActionHandler
  }

  @ViewBuilder
  func buttonContent(item: KeyboardLayoutItem) -> some View {
    HamsterKeyboardActionButtonContent(
      buttonExtendCharacter: skinExtend,
      action: item.action,
      appearance: appearance,
      context: context
    )
  }

  var autocompleteToolbar: some View {
    HamsterAutocompleteToolbar()
      .opacity(context.prefersAutocomplete ? 1 : 0) // Still allocate height
  }

  var keyboard: some View {
    SystemKeyboard(
      layout: layoutProvider.keyboardLayout(for: context),
      appearance: appearance,
      actionHandler: actionHandler,
      keyboardContext: context,
      actionCalloutContext: actionCalloutContext,
      inputCalloutContext: inputCalloutContext,
      width: width,
      buttonView: { layoutItem, keyboardWidth, inputWidth in
        SystemKeyboardButtonRowItem(
          content: buttonContent(item: layoutItem),
          item: layoutItem,
          keyboardContext: context,
          keyboardWidth: keyboardWidth,
          inputWidth: inputWidth,
          appearance: appearance,
          actionHandler: actionHandler
        )
      }
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      if context.keyboardType != .emojis {
        autocompleteToolbar
      }
      keyboard
    }
  }

  var width: CGFloat {
    // TODO: 横向的全面屏需要减去左右两边的听写键和键盘切换键
    return !context.isPortrait && context.hasDictationKey ? standardKeyboardWidth - 150 : standardKeyboardWidth
  }

  var standardKeyboardWidth: CGFloat {
    KeyboardInputViewController.shared.view.frame.width
  }
}