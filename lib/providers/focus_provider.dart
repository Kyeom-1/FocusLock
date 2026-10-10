import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task.dart';

class FocusProvider extends ChangeNotifier {
  Timer? _timer;
  Task? currentTask;
  int remainingSeconds=0;
  bool isRunning=false;

  /// True once the countdown has hit zero (session over, task not yet finished).
  bool get timeUp => currentTask!=null && remainingSeconds<=0;

  String get formattedTime {
    final m=remainingSeconds~/60,s=remainingSeconds%60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }
  double get progress {
    if(currentTask==null)return 0;
    final total=currentTask!.durationMinutes*60;
    return total==0?0:1-(remainingSeconds/total);
  }

  void start(Task task) {
    _timer?.cancel();currentTask=task;
    remainingSeconds=task.durationMinutes*60;isRunning=true;notifyListeners();
    _timer=Timer.periodic(const Duration(seconds:1),(_){
      if(remainingSeconds<=0){stop();return;}
      remainingSeconds--;notifyListeners();
    });
  }
  void pause(){_timer?.cancel();isRunning=false;notifyListeners();}
  void resume(){
    if(currentTask==null||remainingSeconds<=0)return;
    isRunning=true;notifyListeners();
    _timer=Timer.periodic(const Duration(seconds:1),(_){
      if(remainingSeconds<=0){stop();return;}
      remainingSeconds--;notifyListeners();
    });
  }
  void stop(){_timer?.cancel();_timer=null;isRunning=false;notifyListeners();}
  @override void dispose(){_timer?.cancel();super.dispose();}
}
