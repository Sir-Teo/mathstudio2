# MathStudio2

MathStudio2 is a web-based mathematical notebook application built with Flutter. It provides an interactive environment for mathematical computations, similar to Mathematica, allowing users to create, edit, and execute mathematical expressions alongside markdown documentation.

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- A modern web browser

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Sir-Teo/mathstudio2.git
cd mathstudio2
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```


## Usage Examples

### Creating a Mathematical Expression
```markdown
In[1]: x = 5
Out[1]: 5

In[2]: y = x^2 + 2*x + 1
Out[2]: 36
```

### Using Markdown with LaTeX
```markdown
# Integration Example

The definite integral of $e^x$ from 0 to 1 is:

$$\int_0^1 e^x dx = e - 1$$
```

### Executing Multiple Cells
```markdown
In[1]: a = [1, 2, 3, 4, 5]
Out[1]: [1, 2, 3, 4, 5]

In[2]: sum(a)/len(a)
Out[2]: 3
```
