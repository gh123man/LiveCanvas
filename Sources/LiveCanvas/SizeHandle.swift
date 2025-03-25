import SwiftUI

struct SizeHandle<ViewContext>: View {
    
    @Binding var selected: Layer<ViewContext>
    
    // The handle position we display on-screen
    @State private var handlePos: CGPoint = .zero
    
    // To control gesture logic
    @State private var gestureOngoing = false
    
    // Store starting data when drag begins
    @State private var initialFrame: CGRect = .zero
    
    var externalGeometry: GeometryProxy
    var onStartMove: () -> ()
    
    // Called whenever we need to re-sync the handle's position
    // with the actual bottom-right corner of whatever frame is visible.
    private func computeHandlePosition(frame: CGRect? = nil) {
        let ref = frame ?? selected.presentedFrame
        handlePos = boundsCheck(CGPoint(x: ref.maxX, y: ref.maxY))
    }
    
    // Ensure the point doesn't exceed the canvas bounds
    private func boundsCheck(_ point: CGPoint) -> CGPoint {
        var pt = point
        pt.x = max(0, min(pt.x, externalGeometry.size.width))
        pt.y = max(0, min(pt.y, externalGeometry.size.height))
        return pt
    }
    
    func computeFrame(frame: CGRect, gestureLocation: CGPoint) -> (CGRect, CGPoint) {
        // On first movement, capture the current state
        if !gestureOngoing {
            gestureOngoing = true
            onStartMove()
            initialFrame = frame
        }
        
        // 1) Figure out where the user is dragging the handle
        let rawDragLocation = gestureLocation
        let clampedDragLocation = boundsCheck(rawDragLocation)
        
        // 2) We want the parent's top-left corner pinned at initialFrame.origin.
        //    So the new bottom-right corner is at the drag location.
        //    Hence, newSize = dragLocation - initialFrame.origin
        
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        
        switch selected.resize {
        case .any:
            // 3) Enforce min sizes
            newWidth = max(clampedDragLocation.x - initialFrame.minX, selected.minSize.width)
            newHeight = max(clampedDragLocation.y - initialFrame.minY, selected.minSize.height)
        case .proportional:
            let wChange = clampedDragLocation.x - initialFrame.minX
            let hChange = clampedDragLocation.y - initialFrame.minY

            let aspectRatio = frame.width / frame.height
            let widthBasedHeight = wChange / aspectRatio
            let heightBasedWidth = hChange * aspectRatio

            if widthBasedHeight >= hChange {
                newWidth = max(wChange, selected.minSize.width)
                newHeight = newWidth / aspectRatio
            } else {
                newHeight = max(hChange, selected.minSize.height)
                newWidth = newHeight * aspectRatio
            }

            // Enforce min size again in case aspect ratio push violates it
            if newWidth < selected.minSize.width {
                newWidth = selected.minSize.width
                newHeight = newWidth / aspectRatio
            }
            if newHeight < selected.minSize.height {
                newHeight = selected.minSize.height
                newWidth = newHeight * aspectRatio
            }
            
        default:
            // Should not be reachable
            return (frame, gestureLocation)
        }
        
        // 4) Update the main frame (keep origin fixed, change size)
        let finalFrame = CGRect(
            x: initialFrame.minX,
            y: initialFrame.minY,
            width: newWidth,
            height: newHeight
        )
        
        // 5) The actual handle position (bottom-right of the parent) might differ
        //    if we had to clamp to minSize. So let's use the parent's new bottom-right.
        let finalBottomRight = CGPoint(
            x: frame.maxX,
            y: frame.maxY
        )
        return (finalFrame, boundsCheck(finalBottomRight))
    }
    
    var body: some View {
        Circle()
            .foregroundColor(.white)
            .overlay(
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .resizable()
                    .frame(width: 14, height: 14)
                    .foregroundColor(.black.opacity(0.6))
            )
            .frame(width: 24, height: 24)
            .position(handlePos)
            .shadow(radius: 5)
            .onAppear {
                // Set initial handle position once everything is laid out
                computeHandlePosition()
            }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        let (frame, point) = computeFrame(frame: selected.presentedFrame, gestureLocation: gesture.location)
                        selected.presentedFrame = frame
                        handlePos = point
                    }
                    .onEnded { _ in
                        gestureOngoing = false
                        // Ensure our handle is snapped precisely at the final corner
                        computeHandlePosition()
                    }
            )
            // Also re-sync handle if frame changes externally
            .onChange(of: selected.presentedFrame) { newFrame in
                computeHandlePosition(frame: newFrame)
            }
    }
}
