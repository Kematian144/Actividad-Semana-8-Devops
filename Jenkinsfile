pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
    }

    environment {
        IMAGE_NAME = 'imagen_vehiculos'
        APP_CONTAINER = 'contenedor_vehiculos'
        DB_CONTAINER = 'mariadb_vehiculos'
        DOCKER_NETWORK = 'vehiculos_net'
        DB_NAME = 'Sucursal'
        DB_USER = 'vehiculos'
        DB_PASSWORD = 'Vehiculos1234'
        DB_ROOT_PASSWORD = 'Root1234'
    }

    stages {
        stage('Descargar codigo') {
            steps {
                checkout scm
            }
        }

        stage('Compilar WAR') {
            steps {
                sh 'chmod +x mvnw'
                sh './mvnw clean package -DskipTests'
            }
        }

        stage('Preparar base de datos') {
            steps {
                sh '''
                    docker network inspect "$DOCKER_NETWORK" >/dev/null 2>&1 || \
                    docker network create "$DOCKER_NETWORK"

                    if ! docker ps -a --format '{{.Names}}' | grep -qx "$DB_CONTAINER"; then
                        docker run -d \
                          --name "$DB_CONTAINER" \
                          --network "$DOCKER_NETWORK" \
                          --restart unless-stopped \
                          -e MARIADB_ROOT_PASSWORD="$DB_ROOT_PASSWORD" \
                          -e MARIADB_DATABASE="$DB_NAME" \
                          -e MARIADB_USER="$DB_USER" \
                          -e MARIADB_PASSWORD="$DB_PASSWORD" \
                          -v vehiculos_db_data:/var/lib/mysql \
                          mariadb:11.4
                    else
                        docker start "$DB_CONTAINER" >/dev/null 2>&1 || true
                    fi

                    INTENTO=0
                    until docker exec "$DB_CONTAINER" \
                      mariadb-admin ping -uroot -p"$DB_ROOT_PASSWORD" --silent; do
                        INTENTO=$((INTENTO + 1))
                        if [ "$INTENTO" -ge 30 ]; then
                            docker logs "$DB_CONTAINER"
                            exit 1
                        fi
                        sleep 2
                    done
                '''
            }
        }

        stage('Construir imagen Docker') {
            steps {
                sh 'docker build -t "$IMAGE_NAME" .'
            }
        }

        stage('Desplegar Tomcat') {
            steps {
                sh '''
                    docker rm -f "$APP_CONTAINER" >/dev/null 2>&1 || true

                    docker run -d \
                      --name "$APP_CONTAINER" \
                      --network "$DOCKER_NETWORK" \
                      --restart unless-stopped \
                      -p 9090:8080 \
                      -e DB_URL="jdbc:mysql://$DB_CONTAINER:3306/$DB_NAME?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC" \
                      -e DB_USER="$DB_USER" \
                      -e DB_PASSWORD="$DB_PASSWORD" \
                      "$IMAGE_NAME"
                '''
            }
        }

        stage('Verificar aplicacion') {
            steps {
                sh '''
                    INTENTO=0
                    until curl -fsS http://localhost:9090/vehiculosBuild/; do
                        INTENTO=$((INTENTO + 1))
                        if [ "$INTENTO" -ge 45 ]; then
                            docker logs "$APP_CONTAINER"
                            exit 1
                        fi
                        sleep 2
                    done
                    docker ps
                '''
            }
        }
    }
}