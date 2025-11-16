# Free Public Servers Configuration

## STUN Servers (для определения внешнего IP)
Используем бесплатные STUN сервера Google:
- stun:stun.l.google.com:19302
- stun:stun1.l.google.com:19302
- stun:stun2.l.google.com:19302
- stun:stun3.l.google.com:19302
- stun:stun4.l.google.com:19302

## TURN Servers (для обхода NAT/Firewall)
Используем бесплатный Open Relay Project от Metered:
- URL: turn:openrelay.metered.ca:80, 443
- Username: openrelayproject
- Password: openrelayproject

## Signaling Server Options

### Option 1: Deploy your own on Glitch (Recommended)
1. Перейдите на https://glitch.com
2. Создайте новый Node.js проект
3. Скопируйте содержимое `signaling_server.js` и `server/package.json`
4. Проект автоматически развернётся
5. Используйте URL вашего проекта (например: https://your-project.glitch.me)

### Option 2: Deploy on Render (Free)
1. Перейдите на https://render.com
2. Создайте Web Service
3. Подключите репозиторий или загрузите код
4. Установите команду сборки: `cd server && npm install`
5. Установите команду запуска: `node signaling_server.js`
6. Используйте предоставленный URL

### Option 3: Deploy on Railway (Free tier)
1. Перейдите на https://railway.app
2. Создайте новый проект
3. Загрузите папку server
4. Система автоматически определит Node.js и развернёт
5. Используйте предоставленный URL

### Option 4: Use public demo server (Temporary)
Для тестирования можно использовать:
- https://webrtc-signaling-server.glitch.me

⚠️ **Важно**: Публичный demo сервер может быть недоступен. Рекомендуется развернуть свой.

## Альтернативные TURN серверы (Бесплатные)

### Twilio STUN/TURN (Бесплатный аккаунт)
1. Зарегистрируйтесь на https://www.twilio.com
2. Получите токен для STUN/TURN
3. Добавьте в configuration

### Xirsys (Бесплатный tier)
1. Зарегистрируйтесь на https://xirsys.com
2. Создайте канал
3. Получите credentials
4. Добавьте в configuration

## Текущие настройки

В приложении уже настроены:
- ✅ Бесплатные STUN серверы Google
- ✅ Бесплатные TURN серверы Open Relay Project
- ✅ Публичный signaling server (для теста)

Приложение готово к использованию без локального сервера!
