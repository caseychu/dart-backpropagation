import 'dart:math';
import 'dart:html';

import 'network.dart';
import 'async.dart';

void main() {
	var functions = {
		'parabola': (x) => 2 * x*x / 25 - 1,
		'sine': (x) => sin(x),
		'abs': (x) => (x / 2.5).abs() - 1.0,
		'gaussian': (x) => 2 * exp(-x*x) - 1.0,
		'step': (x) => x < 0 ? -0.8 : 0.8,
		'crazy': (x) => cos(x * sin(x)) * (x < 0 ? 0.9 : -0.4)
	};
	
	var fn = functions['parabola'];
	var data, net, epoch, mse;
	var init = () {
		data = [];
		for (var i = -5.0; i < 5; i += 10.0 / 150.0)
			data.add([[i], [fn(i)]]);
			
		net = new Network(data[0][0].length, data[0][1].length, 2);
		mse = net.trainSet(data);
		epoch = 1;
		if (mse < 1)
			mse = 1; 
	};
	init();
	
	querySelectorAll('button').forEach((button) {
		button.onClick.listen((e) {
			fn = functions[e.target.text];
			init();
		});
	});
	
	var grapher = new Grapher(querySelector('#error'), 1, 20);
	var grapher2 = new Grapher(querySelector('#graph'), 2, 7);

	// Train the network!
	async(75, () {
		epoch += until(50, () => net.trainSet(data));
		var currentMse = net.trainSet(data);
		
		querySelector('#mse').text = currentMse.toString();
		querySelector('#epoch').text = (++epoch).toString();
		grapher.addTimePoint([currentMse / mse]);
		for (var i = 0; i < 90; i++) {
			var pt = 10 * ((i / 90.0) - 0.5);
			grapher2.addTimePoint([fn(pt) / 2.0 + 0.5, net.eval([pt]).get(0) / 2.0 + 0.5]);
		}
	});
}

class Grapher {
	CanvasRenderingContext2D ctx;
	int height, width;
	List<List<num>> units;
	List<List<int>> colors;
	int step;
	
	Grapher(CanvasElement canvas, int units, this.step) {
		this.ctx = canvas.getContext('2d');
		this.height = canvas.height;
		this.width = canvas.width;
		this.units = new List.generate(units, (i) => []);
		
		var rand = new Random();
		this.colors = new List.generate(units, (_) => new List.generate(3, (_) => rand.nextInt(255)));
	}
	
	addTimePoint(List<num> data) {
		for (var i = 0; i < data.length; i++) {
			this.units[i].add(data[i]);
			if (this.units[i].length - 1 > width / step)
				this.units[i].removeAt(0);
		}
		redraw();
	}
	
	redraw() {
		this.ctx.clearRect(0, 0, width, height);
		for (var i = 0; i < this.units.length; i++) {
			this.ctx
				..setStrokeColorRgb(this.colors[i][0], this.colors[i][1], this.colors[i][2], 0.95)
				..beginPath();
				
			for (var t = 0; t < this.units[i].length; t++)
				this.ctx.lineTo(t * step, height * (1 - this.units[i][t]));
			this.ctx
				..stroke()
				..closePath();
		}
	}
}