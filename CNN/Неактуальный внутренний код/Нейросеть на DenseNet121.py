import pandas as pd
import numpy as np
from sklearn.utils import class_weight
from tensorflow.keras.callbacks import ModelCheckpoint
import tensorflow as tf
from tensorflow.keras.applications import DenseNet121
from sklearn.model_selection import train_test_split
from tensorflow.keras.callbacks import EarlyStopping
from tensorflow.keras.callbacks import ReduceLROnPlateau
from tensorflow.keras.optimizers import AdamW
from tensorflow.keras import layers
from tensorflow import keras
import matplotlib.pyplot as plt
from sklearn.utils import resample
import os

#Обязательно делать динамический learning rate, обучать долого, с автоматическим прекращением, 

IMG_WIDTH = (224, 224)  # DenseNet обычно обучалась на 224x224
IMG_CHANNELS = 3
RANDOM_SEED = 42
AUTOTUNE = tf.data.AUTOTUNE
BATCH_SIZE = 32
COEF_FOTO = 15
COEF_POSITIVE = 2


##############################################################

def del_big_data(df):                                                     #Применяется к ISIC_2024 и ISIC_2020 так как в них очень сильный дисбаланс классов, кроме того самих изображений очень много и поэтому их нужно уменьшить.
    df_majority = df[df['label'] == 0]
    df_minority = df[df['label'] == 1]
    n_benign_target = min(len(df_majority), len(df_minority) * COEF_FOTO)

    df_majority_downsampled = resample(df_majority,
                                        replace=False,
                                        n_samples=n_benign_target,
                                        random_state=RANDOM_SEED)

    df_balanced = pd.concat([df_majority_downsampled, df_minority])
    return df_balanced.reset_index(drop=True)

all_filepaths = []
all_labels = []

# #Загрузка данных
# ISIC_2024_meta_path = "A:/Datasets/ISIC_2024_Training_Input/ISIC_2024_Training_GroundTruth.csv"
# ISIC_2024_image_dir = "A:/Datasets/ISIC_2024_Training_Input/ISIC_2024_Training_Input"

# ISIC_2020_meta_path = "A:/Datasets/ISIC_2020_Training_JPEG/ISIC_2020_Training_GroundTruth_v2.csv"
# ISIC_2020_image_dir = "A:/Datasets/ISIC_2020_Training_JPEG/train"

# HAM10000_meta_path  = "A:/Datasets/dataverse_files/HAM10000_metadata.csv"
# HAM10000_image_dir  = "A:/Datasets/dataverse_files/HAM10000_images"

# archive_meta_path  = "A:/Datasets/archive/metadata.csv"
# archive_image_dir  = "A:/Datasets/archive/imgs_part_1"

# mednode_dataset_meta_path  = "A:/Datasets/complete_mednode_dataset/complete_mednode_dataset/metadata.csv"
# mednode_dataset_image_dir  = "A:/Datasets/complete_mednode_dataset/complete_mednode_dataset/foto"

#Загрузка данных
ISIC_2024_meta_path = "/mnt/a/Datasets/ISIC_2024_Training_Input/ISIC_2024_Training_GroundTruth.csv"
ISIC_2024_image_dir = "/mnt/a/Datasets/processed_data/isic_2024_data_crop3"

ISIC_2020_meta_path = "/mnt/a/Datasets/ISIC_2020_Training_JPEG/ISIC_2020_Training_GroundTruth_v2.csv"
ISIC_2020_image_dir = "/mnt/a/Datasets/processed_data/isic_2020_data_crop3"

HAM10000_meta_path  = "/mnt/a/Datasets/dataverse_files/HAM10000_metadata.csv"
HAM10000_image_dir  = "/mnt/a/Datasets/dataverse_files/HAM10000_images"

archive_meta_path  = "/mnt/a/Datasets/archive/metadata.csv"
archive_image_dir  = "/mnt/a/Datasets/archive/imgs_part_1"

mednode_dataset_meta_path  = "/mnt/a/Datasets/complete_mednode_dataset/complete_mednode_dataset/metadata.csv"
mednode_dataset_image_dir  = "/mnt/a/Datasets/complete_mednode_dataset/complete_mednode_dataset/foto"

# ISIC_2024
try:
    df1 = pd.read_csv(ISIC_2024_meta_path)
    df1['filepath'] = df1['isic_id'].apply(lambda x: ISIC_2024_image_dir + "/" + x + '.jpg')
    df1['label'] = df1['malignant'].astype(int)
    df1 = del_big_data(df1)
    all_filepaths.extend(df1['filepath'].tolist())
    all_labels.extend(df1['label'].tolist())

    print(f"Загружен датасет ISIC_2024: {len(df1)} записей.")
except Exception as e:
    print(f"Ошибка загрузки датасета ISIC_2024: {e}")

# ISIC_2020
try:
    df1 = pd.read_csv(ISIC_2020_meta_path)
    df1['filepath'] = df1['image_name'].apply(lambda x: ISIC_2020_image_dir + "/" + x + '.jpg')
    df1['label'] = df1['target'].astype(int)
    df1 = del_big_data(df1)
    all_filepaths.extend(df1['filepath'].tolist())
    all_labels.extend(df1['label'].tolist())
    print(f"Загружен датасет ISIC_2020: {len(df1)} записей.")
except Exception as e:
    print(f"Ошибка загрузки датасета ISIC_2020: {e}")

# # HAM10000
# try:

#     cancer = {
#     'nv': 0,
#     'mel': 1,
#     'bkl': 0,
#     'bcc': 1,
#     'akiec': 1,
#     'vasc': 0,
#     'df': 0
#     }
#     df1 = pd.read_csv(HAM10000_meta_path)
#     df1['filepath'] = df1['image_id'].apply(lambda x: HAM10000_image_dir + "/" + x + '.jpg')
#     df1['label'] = df1['dx'].apply(lambda x: cancer[x])
#     all_filepaths.extend(df1['filepath'].tolist())
#     all_labels.extend(df1['label'].tolist())
#     print(f"Загружен датасет HAM10000: {len(df1)} записей.")
# except Exception as e:
#     print(f"Ошибка загрузки датасета HAM10000: {e}")

# # archive
# # try:
# #     cancer = {
# #     'BCC': 1,
# #     'ACK': 1,
# #     'NEV': 0,
# #     'SEK': 0,
# #     'SCC': 1,
# #     'MEL': 1 
# # }

# #     df1 = pd.read_csv(archive_meta_path)
# #     df1['filepath'] = df1['img_id'].apply(lambda x: archive_image_dir + "/" + x)
# #     df1['label'] = df1['diagnostic'].apply(lambda x: cancer[x])
# #     all_filepaths.extend(df1['filepath'].tolist())
# #     all_labels.extend(df1['label'].tolist())
# #     print(f"Загружен датасет archive: {len(df1)} записей.")
# # except Exception as e:
# #     print(f"Ошибка загрузки датасета archive: {e}")

# # mednode_dataset
# try:
#     df1 = pd.read_csv(mednode_dataset_meta_path)
#     df1['filepath'] = df1['name'].apply(lambda x: mednode_dataset_image_dir + "/" + x)
#     df1['label'] = df1['malignant'].astype(int)
#     all_filepaths.extend(df1['filepath'].tolist())
#     all_labels.extend(df1['label'].tolist())
#     print(f"Загружен датасет mednode_dataset: {len(df1)} записей.")
# except Exception as e:
#     print(f"Ошибка загрузки датасета mednode_dataset: {e}")









##############################################################
# Разделение на обучающую и валидационную выборки

# Эта функция загружает, декодирует, изменяет размер и нормализует
def load_and_preprocess_image(path, label):
    image = tf.io.read_file(path)
    try:
        image = tf.io.decode_jpeg(image, channels=IMG_CHANNELS)
    except tf.errors.InvalidArgumentError:
        image = tf.io.decode_png(image, channels=IMG_CHANNELS)

    shape = tf.shape(image)
    height = shape[0]
    width = shape[1]

    if height != width:
        side = tf.minimum(height, width)
        offset_height = (height - side) // 2
        offset_width = (width - side) // 2

        image = tf.image.crop_to_bounding_box(image, offset_height, offset_width, side, side)

    image = tf.image.resize(image, IMG_WIDTH)
    image = image / 255.0  # Нормализация, такая нормализацая работает лучше для DenseNet121
    return image, label

def augment_image(image, label):
    image = data_augmentation(image, training=True) # training=True важно для некоторых слоев
    return image, label

# data_augmentation = tf.keras.Sequential(
#     [
#         layers.RandomFlip("horizontal", seed=RANDOM_SEED),
#         layers.RandomFlip("vertical", seed=RANDOM_SEED),
#         layers.RandomRotation(
#             factor=(25/360),
#             fill_mode='nearest',
#             seed=RANDOM_SEED
#         ),
#         layers.RandomZoom(
#             height_factor=(-0.1, 0.1),
#             width_factor=(-0.1, 0.1),
#             fill_mode='reflect'
#         ),
#         layers.RandomTranslation(
#             height_factor=0.1,
#             width_factor=0.1,
#             fill_mode='nearest',
#             seed=RANDOM_SEED
#         ),
#         layers.RandomBrightness(
#             factor=0.15,
#             value_range=(0.0, 1.0)
#         ),
#         layers.RandomContrast(factor=0.15),
#         layers.GaussianNoise(stddev=0.01)
#     ],
#     name="data_augmentation",
# )


data_augmentation = tf.keras.Sequential(
    [
        # Флипы
        layers.RandomFlip("horizontal", seed=RANDOM_SEED),
        layers.RandomFlip("vertical", seed=RANDOM_SEED),

        # Ротации, трансляции, масштаб
        layers.RandomRotation(factor=25/360, fill_mode='nearest', seed=RANDOM_SEED),
        layers.RandomZoom(height_factor=(-0.12, 0.12), width_factor=(-0.12, 0.12), fill_mode='reflect', seed=RANDOM_SEED),
        layers.RandomTranslation(height_factor=0.12, width_factor=0.12, fill_mode='nearest', seed=RANDOM_SEED),

        # # Цвет
        # layers.RandomBrightness(factor=0.10, value_range=(0.0, 1.0), seed=RANDOM_SEED),
        # layers.RandomContrast(factor=0.05, seed=RANDOM_SEED),
        # layers.Lambda(lambda img: tf.image.random_saturation(img, lower=0.9, upper=1.1, seed=RANDOM_SEED)),
        # layers.Lambda(lambda img: tf.image.random_hue(img, max_delta=0.05, seed=RANDOM_SEED)),

        # # Шум
        # layers.GaussianNoise(stddev=0.015, seed=RANDOM_SEED),
    ],
    name="enhanced_data_augmentation_tf219",
)

train_paths, val_paths, train_labels, val_labels = train_test_split(
    all_filepaths,
    all_labels,
    test_size=0.2,
    random_state=RANDOM_SEED,
    stratify=all_labels
)

print(f"Размер обучающей выборки: {len(train_paths)}")
print(f"Размер валидационной выборки: {len(val_paths)}")

train_ds = tf.data.Dataset.from_tensor_slices((train_paths, train_labels))
val_ds = tf.data.Dataset.from_tensor_slices((val_paths, val_labels))

train_ds = (
    train_ds
    .shuffle(buffer_size=len(train_paths), seed=RANDOM_SEED) # Перемешивание
    .map(load_and_preprocess_image, num_parallel_calls=AUTOTUNE) # Загрузка и базовая обработка
    .map(augment_image, num_parallel_calls=AUTOTUNE) # **Применение аугментации**
    .batch(BATCH_SIZE) # Формирование батчей
    .prefetch(buffer_size=AUTOTUNE) # Предзагрузка для производительности
)

val_ds = (
    val_ds
    .map(load_and_preprocess_image, num_parallel_calls=AUTOTUNE) # Загрузка и базовая обработка
    .batch(BATCH_SIZE) # Формирование батчей
    .prefetch(buffer_size=AUTOTUNE) # Предзагрузка
)







##############################################################
# Создание модели

input_tensor = keras.Input(shape=(IMG_WIDTH[0], IMG_WIDTH[1], IMG_CHANNELS), name='image_input')

base_model = DenseNet121(
    weights='imagenet',
    include_top=False,
    input_tensor=input_tensor
)

base_model.trainable = False
print(f"Базовая модель {base_model.name} заморожена. Trainable: {base_model.trainable}")

x = base_model.output
x = layers.GlobalAveragePooling2D(name='global_avg_pool')(x)
x = layers.Dropout(0.6, name='head_dropout')(x)
output_tensor = layers.Dense(1, activation='sigmoid', name='class_predictions')(x)

model = keras.Model(inputs=input_tensor, outputs=output_tensor, name='densenet121_transfer')

# model.summary()
# input()

model.compile(
    #optimizer=keras.optimizers.Adam(learning_rate=1e-3),
    optimizer= AdamW(
        learning_rate=1e-3,
        weight_decay=1e-5
    ),
    loss= 'binary_crossentropy',
    metrics=['accuracy', tf.keras.metrics.AUC(name='auc')]
)





##############################################################
#Работа с развесовкой классов
y_train_array = np.array(train_labels)

class_weights = class_weight.compute_class_weight(
    class_weight='balanced',
    classes=np.unique(y_train_array),
    y=y_train_array
)

class_weights_dict = {i : class_weights[i] for i, cls in enumerate(np.unique(y_train_array))}
class_weights_dict[1] = class_weights_dict[1] * COEF_POSITIVE  #Обычная балансировка не помогает, приходится вручную увеличивать вес раковых родинок, тогда на тестовых данных оба значения будут иметь примерно одинаковую точность, иначе злокачественность будет плохо определяться.
print(f"Рассчитанные веса классов: {class_weights_dict}")








##############################################################
# Контрольные точки
parametrs = "model_DenseNet121"
checkpoint_filepath = '/mnt/c/Users/urako/OneDrive/Документы/Code/Mr.-Mole/CNN/checkpoints/' + parametrs + '_{epoch:02d}_{val_loss:.2f}.weights.h5' # Путь к файлу для сохранения
model_checkpoint_callback = ModelCheckpoint(
    filepath=checkpoint_filepath,
    save_weights_only=True, # Сохранять только веса модели, а не всю модель целиком (меньше места, быстрее)
    monitor='val_loss', # Метрика, которую отслеживать для сохранения (обычно val_loss - loss на валидационной выборке)
    mode='min', # В каком направлении должна меняться метрика (min - сохранять при минимальном значении val_loss, max - при максимальном, например, val_accuracy)
    save_best_only=True, # Сохранять только лучшую модель (с наилучшим значением monitor метрики)
    verbose=1 # Выводить сообщения о сохранении контрольных точек
)








##############################################################
# Обучение модели

# lastest = "C:/Users/urako/OneDrive/Документы/Код/Mr.-Mole/checkpoints/model_11_0.67.h5"
# model.load_weights(lastest)


print("\n--- Начало обучения только 'головы' ---")
history = model.fit(
    train_ds,
    epochs=8,
    validation_data=val_ds,
    class_weight=class_weights_dict,
    callbacks=[model_checkpoint_callback],
    initial_epoch=0
)
print("--- Обучение 'головы' завершено ---")



print("\n--- Начало этапа Fine-tuning ---")
base_model.trainable = True # Размораживаем всю базовую модель
print("\n--- Summary после разморозки для Fine-tuning ---")

unfreeze_from_layer_name = 'conv4_block21_0_bn' #149 слой
unfreeze_idx = None
for idx, layer in enumerate(base_model.layers):
    if layer.name == unfreeze_from_layer_name:
        unfreeze_idx = idx
        break
if unfreeze_idx is not None:
    for i, layer in enumerate(base_model.layers):
        layer.trainable = (i >= unfreeze_idx)
    print(f"Заморожены все слои до {unfreeze_from_layer_name} (индекс {unfreeze_idx}).")
else:
    print(f"Слой с именем {unfreeze_from_layer_name} не найден!")

model.compile(
    #optimizer=keras.optimizers.Adam(learning_rate=1e-5),
    optimizer= AdamW(
        learning_rate=1e-5,
        weight_decay=1e-4
    ),
    loss= 'binary_crossentropy',
    metrics=['accuracy', tf.keras.metrics.AUC(name='auc')]
)


weights_dir = "/mnt/c/Users/urako/OneDrive/Документы/Code/Mr.-Mole/CNN/checkpoints" # Находим лучший чекпоинт первого этапа
try:
     print(f"Загрузка лучших весов 'головы' из: {weights_dir} для начала fine-tuning.")
     weight_files = [f for f in os.listdir(weights_dir) if f.endswith('.weights.h5') and f.startswith(parametrs)]
     weight_files.sort(reverse=True)
     best_weight_path = os.path.join(weights_dir, weight_files[0])
     model.load_weights(best_weight_path)
except:
     print("Предупреждение: Не найдены веса для загрузки перед fine-tuning. Продолжаем с текущими.")

print("\n--- Начало обучения всей модели (Fine-tuning) ---")

initial_epoch_fine_tuning = history.epoch[-1] + 1
epochs_fine_tuning = 50 # Сколько эпох хотим обучать на этапе fine-tuning
total_epochs = initial_epoch_fine_tuning + epochs_fine_tuning

early_stopper = EarlyStopping(monitor='val_loss',
                            patience=10,
                            verbose=1, # Выводить сообщение при остановке
                            mode='min',
                            restore_best_weights=True)

reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.2, patience=3, min_lr=1e-8, verbose=1)
                            
print(f"\n--- Начало обучения всей модели (Fine-tuning) с эпохи {initial_epoch_fine_tuning} ---")
history_fine = model.fit(
    train_ds,
    epochs=total_epochs,
    validation_data=val_ds,
    class_weight=class_weights_dict,
    callbacks=[model_checkpoint_callback, early_stopper, reduce_lr],
    initial_epoch=initial_epoch_fine_tuning
)
print("--- Fine-tuning завершен ---")






##############################################################
#Графики обучения

# Объединяем истории обучения первого этапа и fine-tuning'а
history_dict_head = history.history
history_dict_fine = history_fine.history

acc = history_dict_head['accuracy'] + history_dict_fine['accuracy']
val_acc = history_dict_head['val_accuracy'] + history_dict_fine['val_accuracy']
loss = history_dict_head['loss'] + history_dict_fine['loss']
val_loss = history_dict_head['val_loss'] + history_dict_fine['val_loss']

epochs_range_head = range(len(history_dict_head['accuracy']))
epochs_range_fine = range(len(history_dict_head['accuracy']), len(history_dict_head['accuracy']) + len(history_dict_fine['accuracy']))
total_epochs_range = range(len(acc)) # Общий диапазон эпох

plt.figure(figsize=(12, 5))

# График точности
plt.subplot(1, 2, 1)
plt.plot(total_epochs_range, acc, label='Точность на обучении')
plt.plot(total_epochs_range, val_acc, label='Точность на валидации')
plt.axvline(len(epochs_range_head) - 1, color='gray', linestyle='--', label='Начало Fine-tuning') # Вертикальная линия
plt.legend(loc='lower right')
plt.title('Точность (Accuracy)')
plt.xlabel('Эпохи')
plt.ylabel('Точность')

# График потерь
plt.subplot(1, 2, 2)
plt.plot(total_epochs_range, loss, label='Потери на обучении')
plt.plot(total_epochs_range, val_loss, label='Потери на валидации')
plt.axvline(len(epochs_range_head) - 1, color='gray', linestyle='--', label='Начало Fine-tuning') # Вертикальная линия
plt.legend(loc='upper right')
plt.title('Потери (Loss)')
plt.xlabel('Эпохи')
plt.ylabel('Потери')

plt.suptitle('Результаты обучения модели')
plt.tight_layout(rect=[0, 0.03, 1, 0.95])
plt.show()