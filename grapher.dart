import 'dart:math';
import 'dart:html';

class Grapher {
	CanvasRenderingContext2D ctx;
	int height, width;
	List<List<num>> units;
	List<List<int>> colors;
	int step;
	
	Grapher(CanvasElement canvas, int lines, this.step) {
		ctx = canvas.getContext('2d');
		height = canvas.height;
		width = canvas.width;
		units = new List.generate(lines, (i) => []);
		
		var rand = new Random();
		colors = new List.generate(lines, (_) => new List.generate(3, (_) => rand.nextInt(255)));
	}
	
	addTimePoint(List<num> data) {
		for (var i = 0; i < data.length; i++) {
			units[i].add(data[i]);
			if (units[i].length - 1 > width / step)
				units[i].removeAt(0);
		}
		redraw();
	}
	
	redraw() {
		ctx.clearRect(0, 0, width, height);
		for (var i = 0; i < units.length; i++) {
			ctx
				..setStrokeColorRgb(colors[i][0], colors[i][1], colors[i][2], 0.95)
				..beginPath();
				
			for (var t = 0; t < units[i].length; t++)
				ctx.lineTo(t * step, height * (1 - units[i][t]));
			ctx
				..stroke()
				..closePath();
		}
	}
}