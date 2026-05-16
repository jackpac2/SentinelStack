TRUNCATE TABLE order_items, orders, products RESTART IDENTITY CASCADE;

INSERT INTO products (
  name,
  description,
  price,
  category,
  stock,
  image_url,
  rating,
  review_count
) VALUES
  (
    'CloudBuds Pro',
    'Wireless earbuds with clear everyday sound and a compact cloud-white case.',
    59.99,
    'Electronics',
    28,
    'cloudbuds-pro',
    4.8,
    128
  ),
  (
    'Cloud Hoodie',
    'Ultra-soft cotton hoodie with a relaxed fit and calm sky-blue finish.',
    49.99,
    'Fashion',
    34,
    'cloud-hoodie',
    4.7,
    86
  ),
  (
    'CloudMist Humidifier',
    'Quiet room humidifier with a gentle mist for home and desk spaces.',
    39.99,
    'Home & Living',
    19,
    'cloudmist-humidifier',
    4.6,
    64
  ),
  (
    'CloudWatch Lite',
    'Slim fitness watch with everyday activity tracking and soft-touch band.',
    89.99,
    'Electronics',
    22,
    'cloudwatch-lite',
    4.9,
    95
  ),
  (
    'CloudPack Backpack',
    'Water-resistant backpack with organized storage for work and travel.',
    54.99,
    'Office',
    26,
    'cloudpack-backpack',
    4.7,
    72
  ),
  (
    'CloudStep Sneakers',
    'Lightweight sneakers designed for daily movement and clean comfort.',
    69.99,
    'Sports',
    31,
    'cloudstep-sneakers',
    4.8,
    110
  );
