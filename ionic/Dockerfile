# --- Fase 1: compilar la app Ionic/Angular ---
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx ng build --configuration production \
 && if [ -d www/browser ]; then mv www/browser /salida; else mv www /salida; fi

# --- Fase 2: servirla con Nginx ---
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /salida /usr/share/nginx/html
EXPOSE 80
