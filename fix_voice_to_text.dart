// Line 762-767 ตอนนี้ (auto-submit)
} else if (confidence >= 0.8) {
  if (mounted) {
    setState(() => _voicePreviewText = '');
    await provider.processInput(text, isVoice: true);
    _showSuccessToast(context, text, intent);
  }
}

// เปลี่ยนเป็น (ใส่ช่องพิมพ์):
} else if (confidence >= 0.8) {
  if (mounted) {
    setState(() {
      _voicePreviewText = '';
      _textController.text = text; // ใส่ข้อความลงช่องพิมพ์
    });
    FocusScope.of(context).requestFocus(_textFieldFocus); // โฟกัสที่ช่องพิมพ์
  }
}
