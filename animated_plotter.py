import matplotlib.pyplot as plt
import matplotlib.patches as patches
from PIL import Image

def map_bounding_boxes(image_path, predictions):
    """
    Maps bounding box predictions to an image using Matplotlib.

    Args:
        image_path (str): Path to the image file.
        predictions (list): A list of dictionaries, where each dictionary
            represents a bounding box and contains keys like 'x_min', 'y_min',
            'x_max', 'y_max', and optionally 'label'.
    """
    img = Image.open(image_path)
    fig, ax = plt.subplots(1)
    ax.imshow(img)

    for pred in predictions:
        x_min, y_min, x_max, y_max = pred['x_min'], pred['y_min'], pred['x_max'], pred['y_max']
        width = x_max - x_min
        height = y_max - y_min
        rect = patches.Rectangle((x_min, y_min), width, height, linewidth=1, edgecolor='r', facecolor='none')
        ax.add_patch(rect)

        if 'label' in pred:
            ax.text(x_min, y_min, pred['label'], color='white', fontsize=8, bbox=dict(facecolor='red', alpha=0.5))

    plt.show()

# Example usage:
image_path = 'path/to/your/image.jpg'
predictions = [
    {'x_min': 100, 'y_min': 50, 'x_max': 200, 'y_max': 150, 'label': 'Object A'},
    {'x_min': 250, 'y_min': 75, 'x_max': 350, 'y_max': 175, 'label': 'Object B'}
]

map_bounding_boxes(image_path, predictions)