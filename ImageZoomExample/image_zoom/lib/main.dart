import 'package:flutter/material.dart';
import 'package:image_zoom/zoomable_cached_network_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late final TransformationController __transformationController =
      TransformationController();
  late final AnimationController __animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..addListener(() {
      __transformationController.value = __animation.value;
    });
  late final Animation __animation = CurvedAnimation(
    parent: __animationController,
    curve: Curves.fastOutSlowIn,
  );

  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 7),
    vsync: this,
  );

  Offset _offset = Offset.zero;
  double _scale = 1.0;

  double _height = 900;
  double targetX = 0;
  double targetY = 0;

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _zoomToBottom() {
    setState(() {
      // _controller.value
      _scale = 2.0;
      double totalWidth = _height;
      targetX += 250;
      if (targetX > 900) {
        targetY -= 250;
        targetX = 0;
      }
      var screenWidth = MediaQuery.of(context).size.width;

      var ratio = totalWidth > screenWidth
          ? totalWidth / screenWidth
          : screenWidth / totalWidth;
      print(
          'screenWidth:$screenWidth, width:$totalWidth, ratio:$ratio, target:$targetX, targetOnScreen:${targetX / ratio}');
      _offset = Offset(-(targetX / ratio), targetY);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              constrained: false,
              scaleEnabled: false,
              child:
                  // Image.network('https://picsum.photos/900?image=9')
                  ZoomableCachedNetworkImage(
                url: 'https://picsum.photos/900?image=1',
                scale: _scale,
                offset: _offset,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _scale = 1.0;
                  _offset = Offset.zero;
                  targetY = 0;
                  targetX = 0;
                });
              },
              child: const Icon(Icons.clear),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _zoomToBottom,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
