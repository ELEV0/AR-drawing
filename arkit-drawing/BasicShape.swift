import UIKit

enum ShapeOption: String, RawRepresentable {
    case addShape = "Выберите основную форму"
    case addScene = "Выберите файл сцены"
    case togglePlane = "Включение / Отключение визуализации плоскости"
    case undoLastShape = "Отменить последнюю фигуру"
    case resetScene = "Сбросить сцену"
}

enum Shape: String {
    case box = "Квадрат",
         sphere = "Сфера",
         cylinder = "Цилиндр",
         cone = "Конический",
         pyramid = "Пирамида",
         torus = "Торус"
}

enum Size: String {
    case small = "Маленький",
         medium = "Средний",
         large = "Большой",
         extraLarge = "Очень большой"
}
