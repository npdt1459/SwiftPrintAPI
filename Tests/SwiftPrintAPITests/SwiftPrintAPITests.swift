@testable import SwiftPrintAPI
import VaporTesting
import Testing
import Fluent

@Suite("App Tests with DB", .serialized)
struct SwiftPrintAPITests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()
            try await test(app)
            try await app.autoRevert()
        } catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
    
    @Test("Test Hello World Route")
    func helloWorld() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "hello", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string == "Hello, world!")
            })
        }
    }
    
    @Test("Registering a User")
    func registerUser() async throws {
        try await withApp { app in
            let dto = UserCreateDTO(name: "Test User", email: "test@example.com", password: "password123")
            try await app.testing().test(.POST, "users/register", beforeRequest: { req in
                try req.content.encode(dto)
            }, afterResponse: { res async in
                #expect(res.status == .ok)
            })
        }
    }
    
    @Test("Verifying User Login")
    func loginUser() async throws {
        try await withApp { app in
            let registerDTO = UserCreateDTO(name: "Test User", email: "test@example.com", password: "password123")
                    try await app.testing().test(.POST, "users/register", beforeRequest: { req in
                        try req.content.encode(registerDTO)
                    })
            
            let loginDTO = UserLoginDTO(email: "test@example.com", password: "password123")
            try await app.testing().test(.POST, "users/login", beforeRequest: { req in
                try req.content.encode(loginDTO)
            }, afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string.isEmpty == false)
            })
        }
    }
    @Test("Creating a Printer")
    func createPrinter() async throws {
        try await withApp { app in
            // Register + log in first, since printers/register is a protected route
            let registerDTO = UserCreateDTO(name: "Test User", email: "test@example.com", password: "password123")
            try await app.testing().test(.POST, "users/register", beforeRequest: { req in
                try req.content.encode(registerDTO)
            })

            var token = ""
            let loginDTO = UserLoginDTO(email: "test@example.com", password: "password123")
            try await app.testing().test(.POST, "users/login", beforeRequest: { req in
                try req.content.encode(loginDTO)
            }, afterResponse: { res async in
                token = res.body.string
            })

            let printerDTO = PrinterCreateDTO(title: "Test Printer", areaString: "220x220x250")
            try await app.testing().test(.POST, "printers/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(printerDTO)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let printer = try res.content.decode(PrinterDTO.self)
                #expect(printer.title == printerDTO.title)
                #expect(printer.areaString == printerDTO.areaString)
                #expect(printer.totalPrintMinutes == 0)
            })
        }
    }
    
    @Test("User Cannot Access Another User's Printer")
    func printerOwnershipEnforced() async throws {
        try await withApp { app in
            // User A
            let userA = UserCreateDTO(name: "User A", email: "usera@example.com", password: "password123")
            try await app.testing().test(.POST, "users/register", beforeRequest: { req in
                try req.content.encode(userA)
            })
            var tokenA = ""
            try await app.testing().test(.POST, "users/login", beforeRequest: { req in
                try req.content.encode(UserLoginDTO(email: userA.email, password: userA.password))
            }, afterResponse: { res async in
                tokenA = res.body.string
            })

            // User B
            let userB = UserCreateDTO(name: "User B", email: "userb@example.com", password: "password123")
            try await app.testing().test(.POST, "users/register", beforeRequest: { req in
                try req.content.encode(userB)
            })
            var tokenB = ""
            try await app.testing().test(.POST, "users/login", beforeRequest: { req in
                try req.content.encode(UserLoginDTO(email: userB.email, password: userB.password))
            }, afterResponse: { res async in
                tokenB = res.body.string
            })

            // User A creates a printer
            var printerID = UUID()
            // TODO: POST printers/register using tokenA, capture printer.id into printerID
            
            let printerDTO = PrinterCreateDTO(title: "Test Printer", areaString: "220x220x250")
            try await app.testing().test(.POST, "printers/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: tokenA)
                try req.content.encode(printerDTO)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let printer = try res.content.decode(PrinterDTO.self)
                printerID = printer.id!
                #expect(printer.title == printerDTO.title)
                #expect(printer.areaString == printerDTO.areaString)
                #expect(printer.totalPrintMinutes == 0)
            })

            // User B tries to access User A's printer
            // TODO: GET "printers/\(printerID)" using tokenB, assert res.status == .notFound
            
            try await app.testing().test(.GET, "printers/\(printerID)", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: tokenB)
            }, afterResponse: { res async in
                #expect(res.status == .notFound)
            })
        }
    }

    @Test("Creating a Filament")
    func createFilament() async throws {
        try await withApp { app in
            let registerDTO = UserCreateDTO(name: "Test User", email: "test@example.com", password: "password123")
            try await app.testing().test(.POST, "users/register", beforeRequest: { req in
                try req.content.encode(registerDTO)
            })

            var token = ""
            let loginDTO = UserLoginDTO(email: "test@example.com", password: "password123")
            try await app.testing().test(.POST, "users/login", beforeRequest: { req in
                try req.content.encode(loginDTO)
            }, afterResponse: { res async in
                token = res.body.string
            })

            let filamentDTO = FilamentCreateDTO(title: "Test PLA", color: "Black", material: "PLA", weightGrams: 1000, costPerKg: 20)
            try await app.testing().test(.POST, "filaments/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(filamentDTO)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let filament = try res.content.decode(FilamentDTO.self)
                #expect(filament.title == filamentDTO.title)
                #expect(filament.weightGrams == filamentDTO.weightGrams)
                #expect(filament.costPerKg == filamentDTO.costPerKg)
            })
        }
    }

    @Test("Creating a PrintJob")
    func createPrintJob() async throws {
        try await withApp { app in
            let registerDTO = UserCreateDTO(name: "Test User", email: "test@example.com", password: "password123")
            try await app.testing().test(.POST, "users/register", beforeRequest: { req in
                try req.content.encode(registerDTO)
            })

            var token = ""
            let loginDTO = UserLoginDTO(email: "test@example.com", password: "password123")
            try await app.testing().test(.POST, "users/login", beforeRequest: { req in
                try req.content.encode(loginDTO)
            }, afterResponse: { res async in
                token = res.body.string
            })

            // PrintJob needs a real printer + filament to reference, so create both first
            var printerID = UUID()
            let printerDTO = PrinterCreateDTO(title: "Test Printer", areaString: "220x220x250")
            try await app.testing().test(.POST, "printers/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(printerDTO)
            }, afterResponse: { res async throws in
                let printer = try res.content.decode(PrinterDTO.self)
                printerID = printer.id!
            })

            var filamentID = UUID()
            let filamentDTO = FilamentCreateDTO(title: "Test PLA", color: "Black", material: "PLA", weightGrams: 1000, costPerKg: 20)
            try await app.testing().test(.POST, "filaments/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(filamentDTO)
            }, afterResponse: { res async throws in
                let filament = try res.content.decode(FilamentDTO.self)
                filamentID = filament.id!
            })

            let printJobDTO = PrintJobCreateDTO(duration: 120, weightGrams: 50, success: true, printerID: printerID, filamentID: filamentID)
            try await app.testing().test(.POST, "printJobs/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(printJobDTO)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let printjob = try res.content.decode(PrintJobDTO.self)
                #expect(printjob.duration == printJobDTO.duration)
                #expect(printjob.weightGrams == printJobDTO.weightGrams)
                #expect(printjob.cost == 1.0)
            })
        }
    }

}
