//
//  SavingsOpportunitiesView.swift
//  DissoApp
//
//  Created by Ishaaq Ahmed on 09/02/2024.
//  Copyright © 2024 Ishaaq. All rights reserved.
//

import SwiftUI

struct SavingsOpportunitiesView: View {
    @ObservedObject var viewModel: TransactionViewModel
    @State private var sortOption: SortOption = .highestToLowest
    @State private var selectedCategory: String = "All Categories"

    var body: some View {
        NavigationView {
            VStack(spacing: 20) { // Increase spacing for better use of white space
                // Sort and Category Pickers moved into a horizontal stack for compact UI
                HStack {
                    Picker("Sort by", selection: $sortOption) {
                        Text("Highest to Lowest").tag(SortOption.highestToLowest)
                        Text("Lowest to Highest").tag(SortOption.lowestToHighest)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    Picker("Category", selection: $selectedCategory) {
                        Text("All Categories").tag("All Categories")
                        ForEach(viewModel.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                if viewModel.savingsOpportunities.isEmpty {
                    Spacer()
                    Text("No saving opportunities")
                        .font(.headline)
                        .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(sortedSavingsOpportunities) { opportunity in
                            SavingsOpportunityRow(opportunity: opportunity)
                                .padding(.vertical, 8) // Add padding for each row for better spacing
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarTitle("Savings Opportunities", displayMode: .inline) // Use inline for more space
            .padding(.top)
        }
    }
    
    private var sortedSavingsOpportunities: [ProductSavings] {
        let filteredOpportunities = viewModel.savingsOpportunities.filter { opportunity in
            selectedCategory == "All Categories" || opportunity.category == selectedCategory
        }
        
        switch sortOption {
        case .highestToLowest:
            return filteredOpportunities.sorted { $0.savingsAmount > $1.savingsAmount }
        case .lowestToHighest:
            return filteredOpportunities.sorted { $0.savingsAmount < $1.savingsAmount }
        }
    }

    enum SortOption {
        case highestToLowest, lowestToHighest
    }
}

struct SavingsOpportunityRow: View {
    var opportunity: ProductSavings
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) { // Reduced spacing for a compact look
                Text(opportunity.productName)
                    .font(.headline)
                Text("Cheapest at \(opportunity.cheapestStore)")
                    .font(.subheadline)
                Text("Compared to \(opportunity.mostExpensiveStore)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text("Save £\(opportunity.savingsAmount, specifier: "%.2f")")
                .bold()
                .foregroundColor(.green) // Use color to highlight savings
        }
        .padding() // Ensure padding is sufficient to make the content breathable
    }
}



struct SavingsOpportunitiesView_Previews: PreviewProvider {
    static var previews: some View {
        // Create an instance of TransactionViewModel for preview purposes
        let viewModel = TransactionViewModel()
        // Now pass this instance to your SavingsOpportunitiesView
        SavingsOpportunitiesView(viewModel: viewModel)
    }
}

