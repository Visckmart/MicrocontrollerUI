# MicrocontrollerUI
Pequeno aplicativo para Mac desenvolvido no início de 2019 para monitorar e controlar um micro-controlador (NodeMCU).

Ao conectar um micro-controlador pelo USB no Mac e abrir o aplicativo ele aparecerá na lista de dispositivos conectados.
Ao ser escolhido, o aplicativo tenta se conectar e **lista todos os arquivos** .lua que estão contidos nele.

É possível **enviar comandos** diretamente para o micro-controlador e por meio da interface
o usuário pode **executar os programas** contidos no dispositivo, **visualizar a saída** em tempo real,
**enviar novos programas e reenviá-los** com apenas um clique caso alterações tenham sido feitas desde o último envio do programa.

A comunicação em baixo nível entre o aplicativo e os dispositivos é feita com base em 2 arquivos disponíveis para download no site do
Arduino ([link](https://playground.arduino.cc/Interfacing/Cocoa/#CodeDownload)). Já a interface e os recursos de alto-nível foram totalmente feitos por mim usando Swift. Além da camada de abstração que desenvolvi em Objective-C para simplificar o uso das funções de comunicação com os dispositivos e exercitar meus conhecimentos da linguagem.

### Exemplo de uso
![Exemplo 2](./screenshots/exemplo-execucao-2.png)
### Executando os testes unitários
![Executando os testes unitários](./screenshots/desenvolvimento-teste.png)
### Exemplo com feedback na interface
![Exemplo Recente](./screenshots/exemplo-execucao-recente.png)
