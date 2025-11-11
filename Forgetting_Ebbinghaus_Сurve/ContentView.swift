//
//  ContentView.swift
//  Forgetting_Ebbinghaus_Сurve
//
//  Created by mac on 05.11.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RecallListViewModel()
    @State private var newItemContent: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.items.isEmpty {
                    VStack {
                        Spacer()
                        Text("No items yet.")
                            .font(.title)
                        Text("Add something you want to remember!")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.items) { item in
                                RecallItemRowView(
                                    item: item,
                                    reminderDates: viewModel.getReminderDates(for: item),
                                    nextReminderDate: viewModel.getNextReminderDate(for: item)
                                )
                                .padding(.horizontal)
                                
                                Divider()
                            }
                        }
                    }
                }
                
                HStack {
                    TextField("What do you want to remember?", text: $newItemContent)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: addItem) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                    .disabled(newItemContent.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Recall List")
            // --- ДОБАВЛЕННЫЙ БЛОК КОДА ---
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    // Кнопка для вывода списка уведомлений в консоль
                    Button {
                        viewModel.logAllPendingNotifications()
                    } label: {
                        Label("Show Log", systemImage: "list.bullet.rectangle.portrait")
                    }
                    
                    // Кнопка для удаления всех запланированных уведомлений
                    Button {
                        viewModel.cancelAllPendingNotifications()
                    } label: {
                        Label("Cancel All", systemImage: "trash.circle.fill")
                    }
                }
            }
            // --- КОНЕЦ БЛОКА ---
        }
        .onAppear(perform: viewModel.requestNotificationPermission)
    }
    
    private func addItem() {
        viewModel.addItem(content: newItemContent)
        newItemContent = ""
    }
}

#Preview {
    ContentView()
}
