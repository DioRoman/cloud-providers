# Домашнее задание к занятию «Безопасность в облачных провайдерах»  

Используя конфигурации, выполненные в рамках предыдущих домашних заданий, нужно добавить возможность шифрования бакета.

---
## Задание 1. Yandex Cloud   

1. С помощью ключа в KMS необходимо зашифровать содержимое бакета:

 - создать ключ в KMS;

https://github.com/DioRoman/cloud-providers/blob/main/terraform/encrypt.tf

 - с помощью ключа зашифровать содержимое бакета, созданного ранее.

 <img width="800" height="348" alt="Снимок экрана 2025-11-07 185914" src="https://github.com/user-attachments/assets/68c5ecf9-6f78-40ef-a979-8a75c6a7432f" />

 Видим, что файл зашифрован и не отображается на сайте.

 <img width="531" height="204" alt="Снимок экрана 2025-11-07 184231" src="https://github.com/user-attachments/assets/efc8572e-376e-4bc6-89c6-e4ca01942995" />


2. (Выполняется не в Terraform)* Создать статический сайт в Object Storage c собственным публичным адресом и сделать доступным по HTTPS:

  - создал bucket с название test-sert-dio-roman.com

  <img width="845" height="78" alt="Снимок экрана 2025-11-08 152546" src="https://github.com/user-attachments/assets/d21d02f0-8a90-4ce8-adc9-343ea9446b17" />

   - подключил хостинг 

  <img width="640" height="737" alt="Снимок экрана 2025-11-08 152940" src="https://github.com/user-attachments/assets/121c4063-be79-4dd5-bd86-6e536880b905" />

  - загрузил index.html

  <img width="981" height="273" alt="Снимок экрана 2025-11-08 152934" src="https://github.com/user-attachments/assets/1ea68586-ced8-4bdd-8437-4b921ad690e2" />

  <img width="397" height="154" alt="image" src="https://github.com/user-attachments/assets/35225be2-d896-4f67-9b2c-7536dc0a2916" />

 - создал сертификатс именем test-sert-dio-roman.com и сделал TXT DNS запись

  <img width="724" height="1068" alt="image" src="https://github.com/user-attachments/assets/091b967a-1944-424b-acc9-8bc00fc9e5da" />

  - проверяем DNS записи

   <img width="1328" height="467" alt="Снимок экрана 2025-11-08 153926" src="https://github.com/user-attachments/assets/daea9ddf-de1b-4d6c-ac81-a7e4590eb6e6" />

 - в качестве результата предоставить скриншот на страницу с сертификатом в заголовке (замочек).

   Так и не прошел валидацию. Пробовал все способы.

   <img width="997" height="708" alt="image" src="https://github.com/user-attachments/assets/39c3de7b-de5a-4bba-87e4-af4978b015a7" />
   
