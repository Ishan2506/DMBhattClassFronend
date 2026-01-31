enum ChatStep {
  askStandard,
  askSubject,
  askChapter,
  searching,
  done,
}

class DmaiSession {
  ChatStep step = ChatStep.askStandard;
  String? standard;
  String? subject;
  String? chapter;

  void reset() {
    step = ChatStep.askStandard;
    standard = null;
    subject = null;
    chapter = null;
  }
}
