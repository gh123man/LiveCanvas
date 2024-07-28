//
//  File.swift
//  
//
//  Created by Brian Floersch on 7/28/24.
//

//import Foundation
//import SwiftUI
//
//
//struct Builder: Identifiable {
//   
//    let id = UUID()
//    
//    var build: () -> some View
//    
//    init(build: @escaping () -> some View) {
//        self.build = build
//    }
//    
//    
//}
//
//struct TestView: View {
//    
//    var bs: [Builder]
//    
//    var body: some View {
//        bs[0].build()
//    
//    }
//}
//
//
//#Preview {
//    TestView(bs: [
//        Builder {
//            Text("foo")
//        }
//    ])
//}
