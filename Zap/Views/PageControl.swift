//
//  PageControl.swift
//  Zap
//
//  Created by Zigao Wang on 11/6/24.
//

import SwiftUI

struct PageControl: View {
    var numberOfPages: Int
    @Binding var currentPage: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages) { index in
                Circle()
                    .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.5))
                    .frame(width: 10, height: 10)
            }
        }
    }
}