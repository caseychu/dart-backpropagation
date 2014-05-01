import 'dart:typed_data';
import 'dart:math';

class Matrix {
	
	final int m, n;
	Float64List _data;
	
	Matrix(int m, [int n, List data]) :
			m = m,
			n = n != null ? n : m 
	{
		_data = data != null ?
			new Float64List.fromList(data) :
			new Float64List(this.m * this.n);
	}
	
	// Copies a matrix.
	Matrix.fromMatrix(Matrix mat) : this(mat.m, mat.n, mat._data);
	
	// Creates a column vector from a list.
	Matrix.fromList(List<double> list) : this(list.length, 1, list);
	
	// Identity matrix: main diagonal of ones.
	factory Matrix.I(int n) {
		var mat = new Matrix(n);
		for (int i = 0; i < n; i++)
			mat._data[i * n + i] = 1;
		return mat;
	}
	
	factory Matrix.generate(int m, int n, Function f(int i, int j)) {
		var result = new Matrix(m, n);
		for (var i = 0; i < m; i++)
			for (var j = 0; j < n; j++)
				result._data[i * n + j] = f(i, j);
		return result;
	}
	
	// Row operators.
	operator [](int i) => new Float64List.view(_data.buffer, _data.elementSizeInBytes * i * n, n);
	operator []=(int i, Float64List row) => _data.setRange(i * m, (i + 1) * m, row);
	
	double get(int i) => _data[i];
	
	// Matrix addition.
	Matrix operator +(Matrix mat) {
		if (mat.m != m || mat.n != n)
			throw new ArgumentError('Matrix size mismatch: ${this.m}x${this.n} + ${mat.m}x${mat.n}');
			
		var result = new Matrix.fromMatrix(this);
		for (var i = 0; i < m * n; i++)
			result._data[i] += mat._data[i];
		return result;
	}
	
	// Matrix subtraction.
	Matrix operator -(Matrix mat) {
		if (mat.m != m || mat.n != n)
			throw new ArgumentError('Matrix size mismatch: ${this.m}x${this.n} - ${mat.m}x${mat.n}');
			
		var result = new Matrix.fromMatrix(this);
		for (var i = 0; i < m * n; i++)
			result._data[i] -= mat._data[i];
		return result;
	}
	
	// Scalar multiplication.
	Matrix scalarMultiply(num x) {
		var result = new Matrix.fromMatrix(this);
		for (var i = 0; i < m * n; i++)
			result._data[i] *= x;
		return result;
	}
	
	// Matrix multiplication.
	Matrix matrixMultiply(Matrix mat) {
		if (this.n != mat.m)
			throw new ArgumentError('Matrix size mismatch: ${this.m}x${this.n} * ${mat.m}x${mat.n}');
	
		var result = new Matrix(this.m, mat.n);
		for (var i = 0; i < this.m; i++)
			for (var j = 0; j < mat.n; j++) {
				var sum = 0;
				for (var k = 0; k < this.n; k++)
					sum += this._data[i * this.n + k] * mat._data[k * mat.n + j];
				result._data[i * mat.n + j] = sum;
			}
		return result;
	}
	
	// Entrywise multiplication.
	Matrix operator &(Matrix mat) {
		if (mat.m != m || mat.n != n)
			throw new ArgumentError('Matrix size mismatch: ${this.m}x${this.n} & ${mat.m}x${mat.n}');
			
		var result = new Matrix.fromMatrix(this);
		for (var i = 0; i < m * n; i++)
			result._data[i] *= mat._data[i];
		return result;
	}
	
	// Dot product.
	num dot(Matrix mat) {
		var sum = 0;
		for (var i = 0; i < this._data.length; i++)
			sum += this._data[i] * mat._data[i];
		return sum;
	}
	
	// Matrix and scalar multiplication.
	Matrix operator *(x) {
		if (x is Matrix) 
			return matrixMultiply(x);
		
		else if (x is num)
			return scalarMultiply(x);
			
		throw new ArgumentError('Unsupported multiplication.');
	}
	
	// Transpose.
	Matrix transpose() {
		var result = new Matrix(n, m);
		for (var i = 0; i < m; i++)
			for (var j = 0; j < n; j++)
				result._data[j * m + i] = _data[i * n + j];
		return result;
	}
	
	Matrix operator ~() => transpose();
	
	// Absolute value.
	num mag() => sqrt(dot(this));
	
	Matrix map(Function fn(double)) {
		var result = new Matrix(m, n);
		for (var i = 0; i < m * n; i++)
			result._data[i] = fn(_data[i]);
		return result;
	}
	
	// Extends a vector by 1.
	Matrix extend() {
		var result = new Matrix(m * n + 1, 1);
		result._data.setRange(0, m * n, _data);
		result._data[m * n] = 1.0;
		return result;
	}
	
	// Unextends a vector by 1.
	Matrix unextend() {
		var result = new Matrix(m * n - 1, 1);
		result._data.setRange(0, m * n - 1, _data);
		return result;
	}
	
	bool nan() => _data.any((x) => x.isNaN);
	
	String toString() {
		// A column vector.
		if (n == 1)
			return '#[' + _data.join(', ') + ']';
		
		// An m-by-n matrix.
		return '[\n\t['
			+ new Iterable.generate(m, (i) => this[i].join(', ')).join(']\n\t[')
			+ ']\n]';
	}
}