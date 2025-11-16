# Настройка Firebase для работы в фоне

## Проблема
Когда приложение **полностью закрыто**, Socket.IO соединение разрывается и входящие звонки не приходят.

## Решение: Firebase Cloud Messaging (FCM)

### Шаг 1: Создать проект в Firebase Console

1. Перейти на https://console.firebase.google.com/
2. Нажать "Add project" (Добавить проект)
3. Ввести название: `call-app` (или любое другое)
4. Создать проект

### Шаг 2: Добавить Android приложение

1. В проекте Firebase нажать на значок Android
2. Ввести **Android package name**: `com.webrtc.call`
   (это из файла `android/app/build.gradle.kts`)
3. Скачать файл `google-services.json`
4. Положить файл в папку: `android/app/google-services.json`

### Шаг 3: Настроить build.gradle

Добавить в `android/build.gradle.kts`:
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

Добавить в `android/app/build.gradle.kts`:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // <-- Добавить эту строку
}
```

### Шаг 4: Установить зависимости

```bash
flutter pub get
```

### Шаг 5: Настроить сервер для отправки FCM уведомлений

Обновить `signaling_server.js`:

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Хранить FCM токены пользователей
const userTokens = {};

socket.on('register-fcm-token', (data) => {
  userTokens[socket.shortId] = data.token;
  console.log('FCM token registered for user', socket.shortId);
});

socket.on('offer', async (data) => {
  const targetSocket = users[data.targetUserId];
  
  if (targetSocket) {
    // Отправить через Socket.IO если онлайн
    targetSocket.emit('offer', {
      offer: data.offer,
      callerId: socket.shortId,
    });
  } else {
    // Отправить через FCM если оффлайн
    const targetToken = userTokens[data.targetUserId];
    if (targetToken) {
      const message = {
        token: targetToken,
        notification: {
          title: 'Входящий звонок',
          body: `Звонок от пользователя ${socket.shortId}`,
        },
        data: {
          callerId: socket.shortId,
          offer: JSON.stringify(data.offer),
        },
        android: {
          priority: 'high',
        },
      };
      
      try {
        await admin.messaging().send(message);
        console.log('FCM notification sent');
      } catch (error) {
        console.error('FCM error:', error);
      }
    }
  }
});
```

### Шаг 6: Получить Service Account Key

1. В Firebase Console → Project Settings → Service accounts
2. Нажать "Generate new private key"
3. Сохранить файл как `server/serviceAccountKey.json`
4. **НЕ КОММИТИТЬ** этот файл в git!

### Шаг 7: Установить Firebase Admin SDK на сервере

```bash
cd server
npm install firebase-admin
```

### Шаг 8: Запустить

```bash
# Сервер
cd server
node signaling_server.js

# Приложение
flutter run
```

## Как это работает

1. **Приложение открыто** → Socket.IO работает напрямую
2. **Приложение свернуто** → Socket.IO работает + FCM дублирует
3. **Приложение закрыто** → FCM отправляет уведомление → приложение открывается

## Без Firebase

Если не хотите настраивать Firebase:
- Приложение должно быть **открыто или свернуто** (но не закрыто)
- Свернутое приложение будет получать звонки через Socket.IO
- При полном закрытии звонки приходить не будут

## Текущее состояние

✅ Socket.IO с автопереподключением
✅ Локальные уведомления
✅ Короткие 2-значные ID
✅ Диалог входящего звонка
❌ Firebase не настроен (требует ручной настройки)

Для полной работы в фоне нужно выполнить шаги 1-8 выше.
