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
    
    @Test("User Cannot Access Another User's Filament")
    func filamentOwnershipEnforced() async throws {
        try await withApp { app in
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

            // User A creates a filament
            var filamentID = UUID()
            let filamentDTO = FilamentCreateDTO(title: "Test PLA", color: "Black", material: "PLA", weightGrams: 1000, costPerKg: 20)
            try await app.testing().test(.POST, "filaments/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: tokenA)
                try req.content.encode(filamentDTO)
            }, afterResponse: { res async throws in
                let filament = try res.content.decode(FilamentDTO.self)
                filamentID = filament.id!
            })

            // User B tries to access User A's filament
            try await app.testing().test(.GET, "filaments/\(filamentID)", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: tokenB)
            }, afterResponse: { res async in
                #expect(res.status == .notFound)
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

    @Test("User Cannot Access Another User's PrintJob")
    func printJobOwnershipEnforced() async throws {
        try await withApp { app in
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

            // User A creates a printer + filament + printjob
            var printerID = UUID()
            try await app.testing().test(.POST, "printers/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: tokenA)
                try req.content.encode(PrinterCreateDTO(title: "Test Printer", areaString: "220x220x250"))
            }, afterResponse: { res async throws in
                printerID = try res.content.decode(PrinterDTO.self).id!
            })

            var filamentID = UUID()
            try await app.testing().test(.POST, "filaments/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: tokenA)
                try req.content.encode(FilamentCreateDTO(title: "Test PLA", color: "Black", material: "PLA", weightGrams: 1000, costPerKg: 20))
            }, afterResponse: { res async throws in
                filamentID = try res.content.decode(FilamentDTO.self).id!
            })

            var printjobID = UUID()
            try await app.testing().test(.POST, "printJobs/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: tokenA)
                try req.content.encode(PrintJobCreateDTO(duration: 120, weightGrams: 50, success: true, printerID: printerID, filamentID: filamentID))
            }, afterResponse: { res async throws in
                printjobID = try res.content.decode(PrintJobDTO.self).id!
            })

            // User B tries to access User A's printjob
            try await app.testing().test(.GET, "printJobs/\(printjobID)", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: tokenB)
            }, afterResponse: { res async in
                #expect(res.status == .notFound)
            })
        }
    }

    @Test("PrintJob Patch Recalculates Filament and Printer")
    func printJobPatchRecalculates() async throws {
        try await withApp { app in
            let registerDTO = UserCreateDTO(name: "Test User", email: "test@example.com", password: "password123")
            try await app.testing().test(.POST, "users/register", beforeRequest: { req in
                try req.content.encode(registerDTO)
            })
            var token = ""
            try await app.testing().test(.POST, "users/login", beforeRequest: { req in
                try req.content.encode(UserLoginDTO(email: registerDTO.email, password: registerDTO.password))
            }, afterResponse: { res async in
                token = res.body.string
            })

            var printerID = UUID()
            try await app.testing().test(.POST, "printers/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(PrinterCreateDTO(title: "Test Printer", areaString: "220x220x250"))
            }, afterResponse: { res async throws in
                printerID = try res.content.decode(PrinterDTO.self).id!
            })

            var filamentID = UUID()
            try await app.testing().test(.POST, "filaments/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(FilamentCreateDTO(title: "Test PLA", color: "Black", material: "PLA", weightGrams: 1000, costPerKg: 20))
            }, afterResponse: { res async throws in
                filamentID = try res.content.decode(FilamentDTO.self).id!
            })

            // duration: 120, weightGrams: 50 -> filament drops to 950, printer minutes rise to 120
            var printjobID = UUID()
            try await app.testing().test(.POST, "printJobs/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(PrintJobCreateDTO(duration: 120, weightGrams: 50, success: true, printerID: printerID, filamentID: filamentID))
            }, afterResponse: { res async throws in
                printjobID = try res.content.decode(PrintJobDTO.self).id!
            })

            // Patch: weightGrams 50 -> 80 (delta +30), duration 120 -> 150 (delta +30)
            try await app.testing().test(.PATCH, "printJobs/\(printjobID)", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(PrintJobPatchDTO(duration: 150, weightGrams: 80, success: nil))
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let patched = try res.content.decode(PrintJobDTO.self)
                #expect(patched.weightGrams == 80)
                #expect(patched.duration == 150)
                // costPerKg 20, weightGrams 80 -> (80/1000) * 20 = 1.6
                #expect(patched.cost == 1.6)
            })

            // Filament should have lost the extra 30g: 950 - 30 = 920
            try await app.testing().test(.GET, "filaments/\(filamentID)", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                let filament = try res.content.decode(FilamentDTO.self)
                #expect(filament.weightGrams == 920)
            })

            // Printer should have gained the extra 30 minutes: 120 + 30 = 150
            try await app.testing().test(.GET, "printers/\(printerID)", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                let printer = try res.content.decode(PrinterDTO.self)
                #expect(printer.totalPrintMinutes == 150)
            })
        }
    }

    @Test("PrintJob Delete Reverses Filament and Printer")
    func printJobDeleteReverses() async throws {
        try await withApp { app in
            let registerDTO = UserCreateDTO(name: "Test User", email: "test@example.com", password: "password123")
            try await app.testing().test(.POST, "users/register", beforeRequest: { req in
                try req.content.encode(registerDTO)
            })
            var token = ""
            try await app.testing().test(.POST, "users/login", beforeRequest: { req in
                try req.content.encode(UserLoginDTO(email: registerDTO.email, password: registerDTO.password))
            }, afterResponse: { res async in
                token = res.body.string
            })

            var printerID = UUID()
            try await app.testing().test(.POST, "printers/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(PrinterCreateDTO(title: "Test Printer", areaString: "220x220x250"))
            }, afterResponse: { res async throws in
                printerID = try res.content.decode(PrinterDTO.self).id!
            })

            var filamentID = UUID()
            try await app.testing().test(.POST, "filaments/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(FilamentCreateDTO(title: "Test PLA", color: "Black", material: "PLA", weightGrams: 1000, costPerKg: 20))
            }, afterResponse: { res async throws in
                filamentID = try res.content.decode(FilamentDTO.self).id!
            })

            var printjobID = UUID()
            try await app.testing().test(.POST, "printJobs/register", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(PrintJobCreateDTO(duration: 120, weightGrams: 50, success: true, printerID: printerID, filamentID: filamentID))
            }, afterResponse: { res async throws in
                printjobID = try res.content.decode(PrintJobDTO.self).id!
            })

            try await app.testing().test(.DELETE, "printJobs/\(printjobID)", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async in
                #expect(res.status == .noContent)
            })

            // Filament should be back to its original 1000g
            try await app.testing().test(.GET, "filaments/\(filamentID)", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                let filament = try res.content.decode(FilamentDTO.self)
                #expect(filament.weightGrams == 1000)
            })

            // Printer should be back to 0 minutes
            try await app.testing().test(.GET, "printers/\(printerID)", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                let printer = try res.content.decode(PrinterDTO.self)
                #expect(printer.totalPrintMinutes == 0)
            })
        }
    }

    @Test("Login Fails With Wrong Password")
    func loginFailsWithWrongPassword() async throws {
        try await withApp { app in
            let registerDTO = UserCreateDTO(name: "Test User", email: "test@example.com", password: "password123")
            try await app.testing().test(.POST, "users/register", beforeRequest: { req in
                try req.content.encode(registerDTO)
            })

            try await app.testing().test(.POST, "users/login", beforeRequest: { req in
                try req.content.encode(UserLoginDTO(email: registerDTO.email, password: "wrongPassword"))
            }, afterResponse: { res async in
                #expect(res.status == .unauthorized)
            })
        }
    }

    @Test("Protected Route Rejects Missing Token")
    func protectedRouteRejectsMissingToken() async throws {
        try await withApp { app in
            // No beforeRequest, no bearer token attached at all
            try await app.testing().test(.POST, "printers/register", beforeRequest: { req in
                try req.content.encode(PrinterCreateDTO(title: "Test Printer", areaString: "220x220x250"))
            }, afterResponse: { res async in
                #expect(res.status == .unauthorized)
            })
        }
    }

    @Test("Registering Duplicate Email Fails")
    func duplicateRegistrationFails() async throws {
        try await withApp { app in
            let dto = UserCreateDTO(name: "Test User", email: "test@example.com", password: "password123")
            try await app.testing().test(.POST, "users/register", beforeRequest: { req in
                try req.content.encode(dto)
            }, afterResponse: { res async in
                #expect(res.status == .ok)
            })

            // Same email again - should be rejected, not silently succeed
            try await app.testing().test(.POST, "users/register", beforeRequest: { req in
                try req.content.encode(dto)
            }, afterResponse: { res async in
                #expect(res.status != .ok)
            })
        }
    }
}
