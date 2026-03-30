require("dotenv").config({ override: true });

const http = require("http");

const app = require("./app");
const connectDB = require("./src/config/db");
const { ensureDefaultAdmin } = require("./src/services/adminService");
const { initializeSocket } = require("./src/sockets");

const PORT = process.env.PORT || 5000;

let server;

const startServer = async () => {
  await connectDB();
  await ensureDefaultAdmin();

  server = http.createServer(app);
  initializeSocket(server);

  server.on("error", (error) => {
    if (error.code === "EADDRINUSE") {
      console.error(`Port ${PORT} is already in use. Update PORT in .env or stop the existing process.`);
      process.exit(1);
    }

    console.error("Server failed to start:", error);
    process.exit(1);
  });

  server.listen(PORT, () => {
    console.log(`rapidCare server running on port ${PORT}`);
  });
};

startServer().catch((error) => {
  console.error("Failed to start rapidCare server:", error);
  process.exit(1);
});

process.on("unhandledRejection", (error) => {
  console.error("Unhandled promise rejection:", error);

  if (server) {
    server.close(() => process.exit(1));
    return;
  }

  process.exit(1);
});

process.on("SIGTERM", () => {
  if (!server) {
    process.exit(0);
    return;
  }

  server.close(() => process.exit(0));
});
