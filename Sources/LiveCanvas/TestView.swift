//
//  File.swift
//  
//
//  Created by Brian Floersch on 8/3/24.
//

import Foundation
import SwiftUI

struct TestView: View {
    
    @State var edit = "foo"
    var body: some View {
            VStack {
//                Spacer()
                TextEditor(text: $edit)
//                    .fixedSize(horizontal: false, vertical: true)
            }
    }
}

#Preview {
    TestView()
}
