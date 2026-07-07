import SwiftUI
import PhotosUI

struct ContentView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var purchases: PurchaseManager
    @State private var showingAdd = false
    @State private var showingPaywall = false
    @State private var showingSettings = false
    @State private var editingItem: FurnaceLogItem?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if store.items.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(store.items) { item in
                            row(for: item)
                                .listRowBackground(Theme.background)
                                .contentShape(Rectangle())
                                .onTapGesture { editingItem = item }
                        }
                        .onDelete { offsets in
                            store.delete(at: offsets)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Furnace Log")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if store.canAddMore {
                            showingAdd = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("addButton")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddItemSheet(store: store)
            }
            .sheet(item: $editingItem) { item in
                AddItemSheet(store: store, editing: item)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
            Text("No entries yet")
                .font(Theme.headlineFont)
                .foregroundStyle(.white)
            Text("Tap + to add your first entry.")
                .font(Theme.captionFont)
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func row(for item: FurnaceLogItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(Theme.headlineFont)
                    .foregroundStyle(.white)
                Text(item.detail)
                    .font(Theme.captionFont)
                    .foregroundStyle(.white.opacity(0.7))
                Text("\(item.extra)")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.accent2)
            }
            Spacer()
            Text(item.date.formatted(date: .abbreviated, time: .omitted))
                .font(Theme.captionFont)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.vertical, 6)
    }
}

struct AddItemSheet: View {
    @ObservedObject var store: Store
    var editing: FurnaceLogItem? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var newName: String = ""
    @State private var newDetail: String = ""
    @State private var newExtra: String = ""
    @State private var newDate: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Service Type") {
                    TextField("Service Type", text: $newName)
                        .accessibilityIdentifier("nameField")
                }
                Section("Technician") {
                    TextField("Technician", text: $newDetail)
                        .accessibilityIdentifier("detailField")
                }
                Section("Service Date") {
                    DatePicker("Service Date", selection: $newDate, displayedComponents: .date)
                }
                Section("Notes") {
                    TextField("Notes", text: $newExtra)
                }
            }
            .navigationTitle(editing == nil ? "Add Entry" : "Edit Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .accessibilityIdentifier("saveButton")
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let editing {
                    newName = editing.name
                    newDetail = editing.detail
                    newExtra = editing.extra
                    newDate = editing.date
                }
            }
            .simultaneousGesture(TapGesture().onEnded { hideKeyboard() })
        }
    }

    private func save() {
        if let editing {
            var updated = editing
            updated.name = newName
            updated.detail = newDetail
            updated.extra = newExtra
            updated.date = newDate
            store.update(updated)
        } else {
            let item = FurnaceLogItem(name: newName, detail: newDetail, extra: newExtra, date: newDate)
            store.add(item)
        }
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
