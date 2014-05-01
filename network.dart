import 'matrix.dart';
import 'dart:math';
import 'dart:core';

class Network {

	// Properties of each layer.
	List<Matrix> _layers = new List<Matrix>();
	List<double> _learningRates = new List<double>();
	List<Function> _activationFunctions = new List<Function>();
	List<Function> _activationFunctionsD = new List<Function>();
	
	// For normalizing each input.
	List<double> _min = null;
	List<double> _max = null;
	Map<List<double>, Matrix> _cache = new Map<List<double>, Matrix>();
	
	Network(int inputs, int outputs, {int layerCount: 0, List<Map> layers}) {
		if (layers == null)
			layers = new List<Map>.filled(layerCount, {});
		
		// Customize each layer.
		var neuronCounts = new List<int>();
		neuronCounts.add(inputs);
		layers.forEach((layer) {
			neuronCounts.add(layer['neurons'] != null ? layer['neurons'] : 3 * inputs);
			_learningRates.add(layer['learningRate'] != null ? layer['learningRate'] : 0.01);
			_activationFunctions.add(layer['activationFunction'] != null ? layer['activationFunction'][0] : tanh);
			_activationFunctionsD.add(layer['activationFunction'] != null ? layer['activationFunction'][1] : tanhD);
		});
		neuronCounts[neuronCounts.length - 1] = outputs;
		
		// Generate layers with random weights. Add one input to each layer for the bias.
		var random = new Random();
		var getRandom = (i, j) => 0.15 * (2 * random.nextDouble() - 1);
		for (int i = 1; i < neuronCounts.length; i++)
			_layers.add(new Matrix.generate(neuronCounts[i], neuronCounts[i - 1] + 1, getRandom));
	}
	
	// Trains on a list of data and returns the MSE.
	num trainSet(List<List<List<double>>> data) {
		num sum = 0;
		data.shuffle();
		for (var i = 0; i < data.length; i++)
			sum += train(data[i][0], data[i][1]);
		return sum / data.length;
	}
	
	// Trains on an individual sample and returns the squared error.
	num train(List<double> inputList, List<double> desiredList) {
		List<Matrix> layerOutputs = new List<Matrix>(_layers.length);
		List<Matrix> layerInputs = new List<Matrix>(_layers.length + 1);
		layerInputs[0] = _preprocess(inputList).extend();
		Matrix desired = (new Matrix.fromList(desiredList)).extend();
		
		// Feedforward.
		for (int i = 0; i < _layers.length; i++) {
			layerOutputs[i] = _layers[i] * layerInputs[i];
			layerInputs[i + 1] = layerOutputs[i].map(_activationFunctions[i]).extend();
		}
		
		// Backpropagate.
		Matrix errorSignal;
		for (int i = _layers.length - 1; i >= 0; i--) {
			errorSignal = (errorSignal == null ? desired - layerInputs.last 
			                                   : ~_layers[i + 1] * errorSignal).unextend()
			              & layerOutputs[i].map(_activationFunctionsD[i]);
			_layers[i] = _layers[i] + errorSignal * ~layerInputs[i] * _learningRates[i];
		}
		
		return pow((desired - layerInputs.last).mag(), 2);
	}
	
	// Returns the result for an input.
	Matrix eval(List<double> inputList) {
		Matrix output = _preprocess(inputList);
		for (int i = 0; i < _layers.length; i++)
			output = (_layers[i] * output.extend()).map(_activationFunctions[i]);
		return output;
	}
	Matrix evalDiscrete(List<double> inputList) {
		return eval(inputList).map((x) => x.roundToDouble());
	}
	
	// Returns the number of errors.
	int countErrors(List<List<List<double>>> data) {
		num sum = 0;
		for (var i = 0; i < data.length; i++)
			sum += evalDiscrete(data[i][0]).get(0) != data[i][1][0] ? 1 : 0;
		return sum;
	}
	
	// Calculate the average input value, so we can scale the inputs before we process them.	
	void prime(List<List<List<double>>> data) {
		if (_min == null) {
			_min = new List<double>.filled(data[0][0].length, double.INFINITY);
			_max = new List<double>.filled(data[0][0].length, -double.INFINITY);
		}
		
		data.forEach((sample) {
			var inputList = sample[0];
			for (var i = 0; i < inputList.length; i++) {
				if (inputList[i] > _max[i])
					_max[i] = inputList[i];
				if (inputList[i] < _min[i])
					_min[i] = inputList[i];
			}
		});
	}
	
	// Scale and cache inputs.
	Matrix _preprocess(List<double> inputList) {
		if (_cache.containsKey(inputList))
			return _cache[inputList];
	
		if (_min == null)
			return _cache[inputList] = new Matrix.fromList(inputList);
			
		// Scale each component to -1 < x < 1.
		return _cache[inputList] = new Matrix.generate(inputList.length, 1, 
		    (i, j) => (2 * inputList[i] - (_max[i] + _min[i])) / (_max[i] - _min[i]));
	}
}

double tanh(double x) {
	// If x > 0, then it'd be Infinity/Infinity = NaN.
	if (x > 350.0)
		return 1.0;
		
	var e = exp(2.0 * x);
	return (e - 1.0) / (e + 1.0);
}
double tanhD(double x) {
	var t = tanh(x);
	return 1.0 - t * t;
}

double linear(double x) => x;
double linearD(double x) => 1.0;

double logistic(double x) => 1.0 / (1.0 + exp(-x));
double logisticD(double x) {
	var l = logistic(x);
	return l * (1.0 - l);
}