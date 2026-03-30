import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFilterTap;

  const SearchBarWidget({Key? key, required this.hint, required this.onChanged, this.onFilterTap}) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search, color: Colors.orange),
          suffixIcon: widget.onFilterTap != null
              ? IconButton(icon: const Icon(Icons.tune, color: Colors.orange), onPressed: widget.onFilterTap)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
