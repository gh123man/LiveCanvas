import SwiftUI

struct SizeHandle<ViewContext>: View {
    
    @Binding var selected: Layer<ViewContext>
    
    // The handle position we display on-screen
    @State private var handlePos: CGPoint = .zero
    
    // To control gesture logic
    @State private var gestureOngoing = false
    
    // Store starting data when drag begins
    @State private var initialFrame: CGRect = .zero
    @State private var initialClipFrame: CGRect?
    
    var externalGeometry: GeometryProxy
    var onStartMove: () -> ()
    
    let minSize = CGSize(width: 20, height: 20)
    
    // Called whenever we need to re-sync the handle's position
    // with the actual bottom-right corner of whatever frame is visible.
    private func computeHandlePosition() {
        let ref = selected.clipFrame ?? selected.frame
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
            newWidth = max(clampedDragLocation.x - initialFrame.minX, minSize.width)
            newHeight = max(clampedDragLocation.y - initialFrame.minY, minSize.height)
        case .proportional:
            let wChange = clampedDragLocation.x - frame.origin.x
            let hChange = clampedDragLocation.y - frame.origin.y
            let wProportin = wChange / frame.width
            let hProportin = hChange / frame.height

            if wProportin > hProportin {
                newWidth = wChange
                newHeight = frame.height * wProportin
            } else {
                newWidth = frame.width * hProportin
                newHeight = hChange
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
                        
                        if let clipFrame = selected.clipFrame {
                            let (updatedClipFrame, point) = computeFrame(frame: clipFrame, gestureLocation: gesture.location)
                            selected.clipFrame = updatedClipFrame
                            handlePos = point
                            
                            
                            let oldContentFrame = selected.frame

                            let xRatio = (clipFrame.minX - oldContentFrame.minX) / oldContentFrame.width
                            let yRatio = (clipFrame.minY - oldContentFrame.minY) / oldContentFrame.height
                            let widthRatio = clipFrame.width / oldContentFrame.width
                            let heightRatio = clipFrame.height / oldContentFrame.height

                            let newContentWidth = updatedClipFrame.width / widthRatio
                            let newContentHeight = updatedClipFrame.height / heightRatio

                            let newContentX = updatedClipFrame.minX - xRatio * newContentWidth
                            let newContentY = updatedClipFrame.minY - yRatio * newContentHeight

                            selected.frame = CGRect(x: newContentX, y: newContentY, width: newContentWidth, height: newContentHeight)
                            
                        } else {
                            let (frame, point) = computeFrame(frame: selected.frame, gestureLocation: gesture.location)
                            selected.frame = frame
                            handlePos = point
                        }
                        
                        
                    }
                    .onEnded { _ in
                        gestureOngoing = false
                        // Ensure our handle is snapped precisely at the final corner
                        computeHandlePosition()
                    }
            )
            // Also re-sync handle if frame changes externally
            .onChange(of: selected.frame) { _ in
                computeHandlePosition()
            }
    }
}
