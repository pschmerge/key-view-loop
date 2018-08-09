//
// Created by Pierce Schmerge on 8/3/18.
// Copyright (c) 2018 turn pedal labs. All rights reserved.
//

import Foundation
import AppKit

class TestKeyLoopView: NSView {
   var rootView: NSView?
   var keyViews: [TestKeyView] = []
   var rootFrame: NSRect?
   static var sharedTestKeyLoopView = TestKeyLoopView()
   
   required public init?(coder decoder: NSCoder) {
      super.init(coder: decoder)
   }

   private init() { super.init(frame: NSRect()) }

   class func enableForView(_ view: NSView) {
      sharedTestKeyLoopView.rootView = view
      NotificationCenter.default.addObserver(sharedTestKeyLoopView, selector: #selector(mainWindowFlagsChanged), name: Notification.Name(rawValue: "mainWindowFlagsChanged"), object: nil)
   }

   class func disable() {
      sharedTestKeyLoopView.rootView = nil
      sharedTestKeyLoopView.clear()
      NotificationCenter.default.removeObserver(sharedTestKeyLoopView)
   }

   func clear() {
      self.keyViews.removeAll()
      self.removeFromSuperview()
   }
   
   @objc public func mainWindowFlagsChanged(notification: Notification) {
      let currentEventModifierFlags = NSApp.currentEvent?.modifierFlags.rawValue
      let deviceFlags = NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue
      
      if let currentEventModifierFlags = currentEventModifierFlags {
         if currentEventModifierFlags & deviceFlags != 0 {
            if var hitView = rootView, let window = self.rootView?.window {
               while (true) {
                  let mouse: NSPoint? = hitView.convert(window.mouseLocationOutsideOfEventStream, from: nil)
                  var hitSubView = false
                  
                  for (_, subview) in hitView.subviews.enumerated() {
                     if subview == self {
                        continue
                     }
                     
                     if let mouse = mouse {
                        let mouseInRect = NSMouseInRect(mouse, subview.frame, hitView.isFlipped)
                        if mouseInRect {
                           hitView = subview
                           hitSubView = true
                           break
                        }
                     }
                  }
                  
                  if !hitSubView {
                     break
                  }
               }

               if currentEventModifierFlags & NSEvent.ModifierFlags.option.rawValue > 0 {
                  showNextKeyViewLoopFor(view: hitView)
               }
               else if currentEventModifierFlags & NSEvent.ModifierFlags.shift.rawValue > 0 {
                  showPreviousKeyViewLoopFor(view: hitView)
               }
            }
         }
         else {
            clear()
         }
      }
   }

   func insertIntoViewHirarchy() {
      if let _ = self.superview {
         removeFromSuperview()
      }

      if let frame = self.rootView?.window?.contentView?.frame {
         self.frame = frame
      }
      
      rootView?.window?.contentView?.addSubview(self, positioned: .above, relativeTo: nil)
   }
   
   func showNextKeyViewLoopFor(view startView: NSView) {
      nextKeyViewLoopFor(startView: startView) { $0?.nextKeyView }
   }

   func showPreviousKeyViewLoopFor(view startView: NSView) {
      nextKeyViewLoopFor(startView: startView) { $0?.previousKeyView }
   }

   private func nextKeyViewLoopFor(startView: NSView, nextView: (NSView?) -> NSView?) {
      insertIntoViewHirarchy()
      keyViews.removeAll()
      var visitedViews: Set<NSView> = []
      var num = 0
      var view: NSView? = startView

      repeat {
         guard let guardView = view else { assert(false) }
         let frameInWIndow = guardView.convert(guardView.bounds, to: nil)
         let keyView = TestKeyView()
         keyView.frame = convert(frameInWIndow, from: nil)
         keyView.title = String(format: "%1d", num)
         keyView.color = .blue
         keyView.font = NSFont.systemFont(ofSize: 12, weight: NSFont.Weight.medium)
         keyViews.append(keyView)

         num = num.advanced(by: 1)
         visitedViews.insert(guardView)
         view = nextView(view)
      } while view != nil && !visitedViews.contains(view!)

      self.rootFrame = convert(startView.bounds, from: startView)
      self.needsDisplay = true
   }

   func attributedFont(_ font: NSFont, color: NSColor) -> [NSAttributedStringKey: Any] {
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .center
      paragraphStyle.lineBreakMode = .byTruncatingTail
      paragraphStyle.lineSpacing = 0
      
      return [
         NSAttributedStringKey.font: font,
         NSAttributedStringKey.foregroundColor: color,
         NSAttributedStringKey.paragraphStyle: paragraphStyle
      ]
   }
   
   override func draw(_ dirtyRect: NSRect) {
      
      if self.keyViews.count > 0 {
         NSColor.init(red: 1, green: 0, blue: 0, alpha: 0.35).set()
         self.rootFrame?.fill(using: NSCompositingOperation.overlay)
      }
      
      keyViews.forEach {
         keyView in
         drawViewIndicator(keyView: keyView)
      }
   }

   private func drawViewIndicator(keyView: TestKeyView) {
      keyView.color?.set()
      NSBezierPath.defaultLineWidth = 0.5
      NSBezierPath.stroke(NSOffsetRect(keyView.frame!, 0.25, 0.25))
      let attributes = attributedFont(keyView.font!, color: keyView.color!)
      let size = keyView.title?.size(withAttributes: attributes)
      let viewFrame = keyView.frame!
      let textRect = NSOffsetRect(viewFrame, 0, -(size!.height + 2))
      NSColor.clear.set()
      textRect.fill()
      (keyView.title as NSString?)?.draw(in: textRect, withAttributes: attributes)
   }
}
