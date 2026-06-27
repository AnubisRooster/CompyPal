import SwiftUI

struct CompanionsView: View {
    @StateObject private var viewModel = CompanionsViewModel()

    var body: some View {
        List {
            ForEach(viewModel.companions, id: \.id) { companion in
                NavigationLink {
                    ChatView(companion: companion)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(companion.name)
                            .font(.headline)
                        HStack {
                            Text(companion.relationshipStage.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("· \(companion.turnCount) turns")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        if !companion.traits.isEmpty {
                            Text(companion.traits.map { $0.0 }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    let id = viewModel.companions[index].id
                    Task { await viewModel.delete(id) }
                }
            }
        }
        .navigationTitle("Companions")
        .toolbar {
            Button("New", systemImage: "plus") {
                viewModel.showCreate = true
            }
        }
        .sheet(isPresented: $viewModel.showCreate) {
            NavigationStack {
                Form {
                    TextField("Name", text: $viewModel.newName)
                    Section("Personality") {
                        ForEach(viewModel.newTraits.indices, id: \.self) { i in
                            HStack {
                                Text(viewModel.newTraits[i].0.capitalized)
                                Slider(value: $viewModel.newTraits[i].1, in: 0...1)
                            }
                        }
                    }
                }
                .navigationTitle("New Companion")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { viewModel.showCreate = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") { Task { await viewModel.create() } }
                    }
                }
            }
        }
        .task { await viewModel.load() }
    }
}

#Preview { NavigationStack { CompanionsView() } }
