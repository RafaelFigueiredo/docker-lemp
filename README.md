
# Configurando ambiente de desenvolvimento com Docker {NGINX + PHP 7 fpm + MariaDB + PhpMyAdmin}
Nesse artigo vamos aprender a configurar um ambiente de desenvolvimento LEMP(**L**inux Nginx(**E**gine-X) **M**ySQL **P**HP) usando o Docker Compose para orquestrar multiplos containers.
* Linux - Usaremos uma imagem da distro Alpine, pois ela é bem pequena, com menos de 5MB, orientada a segurança e rápida. [
https://alpinelinux.org/]
* NGINX - Servidor HTTP [https://www.nginx.com/]
* MySQL - Em vez da versão padrão do MySQL utilizaremos o **MariaDB** que é uma evolução deste, com mais recursos de segurança e desempenho. [https://mariadb.org/]
* PHP - Instalaremos a versão 7-FPM (FastCGI Process Manager) que aumenta drasticamente a velocidade de ambientes PHP.

## Pré-requisitos
Antes de tudo você deve ter instalado em seu computador o Docker, e o Docker Compose. A documentação oficial é muito boa, então seguem os links:
* https://docs.docker.com/compose/install/
* https://docs.docker.com/install/

Se estiver tendo dor de cabeça para instalar o Docker, use o Docker Toolbox que é indicado para sistemas mais antigos porém resolve muito dos problemas de compatibilidade. Não recomendaria ele para um ambiente de produção por ser mais antigo.
* https://docs.docker.com/toolbox/overview/

## Configurando o Docker
No diretório em que deseja configurar o seu ambiente de desenvolvimento crie as seguintes pastas e arquivos:
* /public_http/
* /nginx/
  * default.conf
* Dockerfile
* docker-compose.yml

A pasta */public_http/* é onde vão ficar os arquivos a serem servidos pelo nosso servidor, se quiser crie um arquivo index.php com o abaixo, ou simplesmente copie para dentro da pasta o site que você quer hospedar:
```php
<?php
echo phpinfo();
?>
```
Dentro da pasta */nginx/* crie um arquivo em branco *default.conf*, ele será responsável pela configuração do nosso servidor Nginx, e na raiz do diretório crie mais dois arquivos: *Dockerfile* e docker-compose.yml
Em breve discutiremos sobre seu conteúdo dos três arquivos que acabamos de criar.

### Dockerfile
O imagem **7-fpm-alpine** é baseada na distro linux Alpine, que é interessante para nosso projeto pois ela é pequena, rápida e segura, conforme o próprio site diz: "Small. Simple. Secure", porém ela não vem com a extensão **mysqli** que precisamos para o PHP, impossibilitando o acesso ao banco de dados.
A solução é construir nossa versão da imagem localmente, instalando a extensão necessária, usando um arquivo *Dockerfile*:
```dockerfile
FROM php:7-fpm-alpine
RUN docker-php-ext-install php7-mysqli
```
O Alpine não utiliza apk ou apt-get, então para instalar a extensão usamos o comando `docker-php-ext-install php7-mysqli`

### docker-compose.yml
Abaixo temos o conteúdo do nosso arquivo *docker-compose.yml* que é responsável por definir os parâmetros da nossa "orquestração".
```yml
version: '3'

networks:
    LEMP:

services:
    nginx:
        image: nginx:stable-alpine
        container_name: LEMP_nginx
        ports:
            - "8080:80"
        volumes:
            - ./code:/code
            - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
        depends_on:
            - php
        networks:
            - LEMP

    mariaDB:
        image: mariadb:latest
        container_name: LEMP_mariaDB
        volumes:
            - ./database:/var/lib/mysql:rw
        ports:
            - "3306:3306"
        depends_on:
            - nginx
        environment:
            - MYSQL_ROOT_PASSWORD=654321          
        networks:
            - LEMP    

    php:
        build: .
        container_name: LEMP_php
        volumes:
            - ./code:/code
        ports:
            - "9000:9000"       
        networks:
            - LEMP

    phpmyadmin:
        image: phpmyadmin/phpmyadmin
        container_name: LEMP_phpMyAdmin
        ports:
            - "8183:80"
        environment:        
            PMA_ARBITRARY: 1
        depends_on:
            - mariaDB
        networks:
            - LEMP
  ```
Analisaremos algumas partes do código mais relevantes:
* Cria uma rede privada para conexão entre os containers.
	```yml
	networks:
		- LEMP
	```
* Define a porta em que o serviço estará disponível (8080), e podemos acessar digitando no navegador: http://localhost:8080/
	```yml
	nginx:  
		...
		ports:  
			-  "8080:80"  
	```
* Cria um volume, um diretório compartilhado entre seu computador e o container onde armazenaremos arquivos persistentes, que não serão apagados quando o container reiniciar ou for finalizado, dados como nosso site propriamente dito, o banco de dados e arquivos de configuração.
	```yml
	nginx:  
		...
			volumes:  
				- ./code:/code 
				- ./nginx/default.conf:/etc/nginx/conf.d/default.conf
	```
* Em vez de simplesmente importar uma imagem pronta usando o comando ```image: php:7-fpm-alpine``` faremos com que o Docker-Compose procure no diretório corrente pelo arquivo *Dockerfile* e crie uma imagem local, isso é necessário para poder instalar a extensão mysqli.
	```yml
	php:  
		build: .
	```


### default.conf
Esse é um arquivo de configuração padrão do Nginx, apenas copie e cole.
```sh
server {
    listen 80;
    index index.php index.html;
    server_name localhost;
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
    root /code;

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
```
## Colocando para rodar
Digite no terminal:
```bash
docker-compose up
```
E...

![enter image description here](http://stevetobak.com/wp-content/uploads/2018/12/its-alive.jpg)
Para visualizar acesse o link: http://localhost:8080
Para utilizar o PhpMyAdmin: http://localhost:8183

## Dica bônus (Codeigniter)
E como dica bônus, se precisar usar o Codeigniter ou algum outro framework semelhante em um subpasta adicione o seguinte trecho a final do arquivo defalt.conf:
```sh
server{
	...
    # Codeigniter in subfolder
    location /sbi/ {
        try_files $uri $uri/ /sbi/index.php;
    }
}
```
E, para solucionar problemas com o script de uploads de arquivos mude a permissão de acesso da pasta onde os arquivos serão armazenados com o comando:
```bash
chmod -R 777 files
```


