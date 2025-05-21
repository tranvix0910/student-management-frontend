##### Dockerfile #####
## Build Stage ##
FROM node:20.19-alpine AS build

WORKDIR /app
COPY . .
RUN npm install
RUN npm run build

## Run Stage ##
FROM nginx:alpine

COPY --from=build /app/build /usr/share/nginx/html

EXPOSE 3000
CMD ["nginx", "-g", "daemon off;"]