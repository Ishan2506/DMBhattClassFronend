class MindMapNode {
  final String name;
  final List<MindMapNode> children;
  bool isExpanded;

  MindMapNode({
    required this.name,
    this.children = const [],
    this.isExpanded = false,
  });

  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    return MindMapNode(
      name: json['name'] ?? '',
      children: (json['children'] as List? ?? [])
          .map((child) => MindMapNode.fromJson(child))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }
}

class MindMapModel {
  final String id;
  final String subject;
  final String unit;
  final String title;
  final String std;
  final MindMapNode root;

  MindMapModel({
    required this.id,
    required this.subject,
    required this.unit,
    required this.title,
    required this.std,
    required this.root,
  });

  factory MindMapModel.fromJson(Map<String, dynamic> json) {
    return MindMapModel(
      id: json['_id'] ?? '',
      subject: json['subject'] ?? '',
      unit: json['unit'] ?? '',
      title: json['title'] ?? '',
      std: json['std'] ?? '',
      root: MindMapNode.fromJson(json['data'] ?? {}),
    );
  }
}
