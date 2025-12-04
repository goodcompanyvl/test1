import Foundation

enum CloudConvertError: LocalizedError {
    case invalidURL
    case noData
    case uploadFailed
    case jobFailed(String)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received"
        case .uploadFailed: return "Upload failed"
        case .jobFailed(let msg): return msg
        case .timeout: return "Request timeout"
        }
    }
}

enum ConversionFormat: String, CaseIterable {
    case pdf, jpg, png, docx, xlsx, pptx, txt
    
    var displayName: String {
        rawValue.uppercased()
    }
}

struct CloudConvertJob: Codable {
    let id: String
    let status: String
    let tasks: [CloudConvertTask]?
    
    struct CloudConvertTask: Codable {
        let id: String
        let name: String
        let operation: String
        let status: String
        let result: TaskResult?
        let message: String?
    }
    
    struct TaskResult: Codable {
        let files: [ResultFile]?
    }
    
    struct ResultFile: Codable {
        let filename: String
        let url: String?
    }
}

actor CloudConvertService {
    static let shared = CloudConvertService()
    
    private let baseURL = "https://api.cloudconvert.com/v2"
    private var apiKey: String = ""
    
    private init() {}
    
    func configure(apiKey: String) {
        self.apiKey = apiKey
        log("🔧 Configured with API key: \(String(apiKey.prefix(20)))...")
    }
    
    func convertToPDF(fileURL: URL, filename: String) async throws -> Data {
        log("📄 Converting to PDF: \(filename)")
        let inputFormat = fileURL.pathExtension.lowercased()
        log("   Input format: \(inputFormat)")
        
        let fileData = try Data(contentsOf: fileURL)
        
        let body: [String: Any] = [
            "tasks": [
                "upload": [
                    "operation": "import/upload"
                ],
                "convert": [
                    "operation": "convert",
                    "input": ["upload"],
                    "input_format": inputFormat,
                    "output_format": "pdf"
                ],
                "export": [
                    "operation": "export/url",
                    "input": ["convert"]
                ]
            ]
        ]
        
        let jobData = try await request(endpoint: "/jobs", method: "POST", body: body)
        let jobResponse = try JSONDecoder().decode(JobResponse.self, from: jobData)
        log("✅ Job created: \(jobResponse.data.id)")
        
        guard let uploadTask = jobResponse.data.tasks?.first(where: { $0.name == "upload" }),
              let uploadResult = try? await getTaskUploadInfo(taskId: uploadTask.id) else {
            throw CloudConvertError.noData
        }
        
        log("📤 Uploading to job task: \(uploadTask.id)")
        try await uploadToTask(data: fileData, filename: fileURL.lastPathComponent, uploadInfo: uploadResult)
        log("✅ File uploaded successfully")
        
        let result = try await waitForJob(jobId: jobResponse.data.id)
        log("✅ Job finished: \(result.status)")
        
        let data = try await downloadResult(from: result)
        log("✅ Downloaded result: \(data.count) bytes")
        
        return data
    }
    
    func convertFromPDF(pdfData: Data, filename: String, to format: ConversionFormat) async throws -> Data {
        log("📄 Converting from PDF to \(format.rawValue.uppercased())")
        log("   Input size: \(pdfData.count) bytes")
        
        let body: [String: Any] = [
            "tasks": [
                "upload": [
                    "operation": "import/upload"
                ],
                "convert": [
                    "operation": "convert",
                    "input": ["upload"],
                    "input_format": "pdf",
                    "output_format": format.rawValue
                ],
                "export": [
                    "operation": "export/url",
                    "input": ["convert"]
                ]
            ]
        ]
        
        let jobData = try await request(endpoint: "/jobs", method: "POST", body: body)
        let jobResponse = try JSONDecoder().decode(JobResponse.self, from: jobData)
        log("✅ Job created: \(jobResponse.data.id)")
        
        guard let uploadTask = jobResponse.data.tasks?.first(where: { $0.name == "upload" }),
              let uploadResult = try? await getTaskUploadInfo(taskId: uploadTask.id) else {
            throw CloudConvertError.noData
        }
        
        log("📤 Uploading to job task: \(uploadTask.id)")
        try await uploadToTask(data: pdfData, filename: filename, uploadInfo: uploadResult)
        log("✅ PDF uploaded successfully")
        
        let result = try await waitForJob(jobId: jobResponse.data.id)
        log("✅ Job finished: \(result.status)")
        
        let data = try await downloadResult(from: result)
        log("✅ Downloaded result: \(data.count) bytes")
        
        return data
    }
    
    func captureWebsite(url: String) async throws -> Data {
        log("🌐 Capturing website: \(url)")
        
        let body: [String: Any] = [
            "tasks": [
                "capture": [
                    "operation": "capture-website",
                    "url": url,
                    "output_format": "pdf",
                    "wait_until": "networkidle0"
                ],
                "export": [
                    "operation": "export/url",
                    "input": ["capture"]
                ]
            ]
        ]
        
        let jobData = try await request(endpoint: "/jobs", method: "POST", body: body)
        let response = try JSONDecoder().decode(JobResponse.self, from: jobData)
        log("✅ Capture job created: \(response.data.id)")
        
        let result = try await waitForJob(jobId: response.data.id)
        log("✅ Capture finished: \(result.status)")
        
        let data = try await downloadResult(from: result)
        log("✅ Downloaded PDF: \(data.count) bytes")
        
        return data
    }
    
    func mergePDFs(pdfURLs: [URL]) async throws -> Data {
        log("📚 Merging \(pdfURLs.count) PDFs")
        
        var uploadTasks: [String] = []
        
        for (index, url) in pdfURLs.enumerated() {
            let task = try await createUploadTask()
            try await uploadFile(fileURL: url, to: task)
            uploadTasks.append(task.id)
            log("✅ Uploaded PDF \(index + 1)/\(pdfURLs.count)")
        }
        
        var tasksDict: [String: Any] = [:]
        
        for (index, taskId) in uploadTasks.enumerated() {
            tasksDict["import-\(index)"] = [
                "operation": "import/upload",
                "task": taskId
            ]
        }
        
        tasksDict["merge"] = [
            "operation": "merge",
            "output_format": "pdf",
            "input": uploadTasks.enumerated().map { "import-\($0.offset)" }
        ]
        
        tasksDict["export"] = [
            "operation": "export/url",
            "input": ["merge"]
        ]
        
        let body: [String: Any] = ["tasks": tasksDict]
        let jobData = try await request(endpoint: "/jobs", method: "POST", body: body)
        let response = try JSONDecoder().decode(JobResponse.self, from: jobData)
        log("✅ Merge job created: \(response.data.id)")
        
        let result = try await waitForJob(jobId: response.data.id)
        log("✅ Merge finished")
        
        let data = try await downloadResult(from: result)
        log("✅ Downloaded merged PDF: \(data.count) bytes")
        
        return data
    }
    
    func ocrPDF(pdfData: Data, filename: String) async throws -> Data {
        log("🔍 OCR processing: \(filename)")
        
        let uploadTask = try await createUploadTask()
        try await uploadData(pdfData, filename: filename, to: uploadTask)
        log("✅ PDF uploaded for OCR")
        
        let body: [String: Any] = [
            "tasks": [
                "import": [
                    "operation": "import/upload",
                    "task": uploadTask.id
                ],
                "ocr": [
                    "operation": "pdf/ocr",
                    "input": ["import"],
                    "language": "eng"
                ],
                "export": [
                    "operation": "export/url",
                    "input": ["ocr"]
                ]
            ]
        ]
        
        let jobData = try await request(endpoint: "/jobs", method: "POST", body: body)
        let response = try JSONDecoder().decode(JobResponse.self, from: jobData)
        log("✅ OCR job created: \(response.data.id)")
        
        let result = try await waitForJob(jobId: response.data.id)
        log("✅ OCR finished")
        
        let data = try await downloadResult(from: result)
        log("✅ Downloaded OCR result: \(data.count) bytes")
        
        return data
    }
    
    private func getTaskUploadInfo(taskId: String) async throws -> TaskUploadInfo {
        log("📤 Getting upload info for task: \(taskId)")
        let data = try await request(endpoint: "/tasks/\(taskId)", method: "GET")
        let response = try JSONDecoder().decode(TaskUploadResponse.self, from: data)
        guard let form = response.data.result?.form else {
            throw CloudConvertError.noData
        }
        return form
    }
    
    private func uploadToTask(data: Data, filename: String, uploadInfo: TaskUploadInfo) async throws {
        guard let uploadURL = URL(string: uploadInfo.url) else {
            throw CloudConvertError.invalidURL
        }
        
        log("📤 Uploading \(filename) (\(data.count) bytes)")
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        for (key, value) in uploadInfo.parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            log("❌ Upload failed: No response")
            throw CloudConvertError.uploadFailed
        }
        
        if !(200...299 ~= httpResponse.statusCode) {
            log("❌ Upload failed: HTTP \(httpResponse.statusCode)")
            throw CloudConvertError.uploadFailed
        }
        
        log("✅ Upload successful: HTTP \(httpResponse.statusCode)")
    }
    
    private func createUploadTask() async throws -> UploadTask {
        log("📤 Creating upload task...")
        let data = try await request(endpoint: "/import/upload", method: "POST", body: [:])
        let response = try JSONDecoder().decode(UploadTaskResponse.self, from: data)
        return response.data
    }
    
    private func uploadFile(fileURL: URL, to task: UploadTask) async throws {
        guard let uploadURL = URL(string: task.result.form.url) else {
            throw CloudConvertError.invalidURL
        }
        
        let fileData = try Data(contentsOf: fileURL)
        log("📤 Uploading file: \(fileURL.lastPathComponent) (\(fileData.count) bytes)")
        
        try await uploadMultipart(
            url: uploadURL,
            parameters: task.result.form.parameters,
            fileData: fileData,
            filename: fileURL.lastPathComponent
        )
    }
    
    private func uploadData(_ data: Data, filename: String, to task: UploadTask) async throws {
        guard let uploadURL = URL(string: task.result.form.url) else {
            throw CloudConvertError.invalidURL
        }
        
        log("📤 Uploading data: \(filename) (\(data.count) bytes)")
        
        try await uploadMultipart(
            url: uploadURL,
            parameters: task.result.form.parameters,
            fileData: data,
            filename: filename
        )
    }
    
    private func uploadMultipart(url: URL, parameters: [String: String], fileData: Data, filename: String) async throws {
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            log("❌ Upload failed: No response")
            throw CloudConvertError.uploadFailed
        }
        
        if !(200...299 ~= httpResponse.statusCode) {
            log("❌ Upload failed: HTTP \(httpResponse.statusCode)")
            throw CloudConvertError.uploadFailed
        }
        
        log("✅ Upload successful: HTTP \(httpResponse.statusCode)")
    }
    
    private func createConversionJob(inputTaskId: String, inputFormat: String, outputFormat: String) async throws -> String {
        log("🔄 Creating conversion job: \(inputFormat) → \(outputFormat)")
        
        let body: [String: Any] = [
            "tasks": [
                "import": [
                    "operation": "import/upload",
                    "task": inputTaskId
                ],
                "convert": [
                    "operation": "convert",
                    "input": ["import"],
                    "input_format": inputFormat,
                    "output_format": outputFormat
                ],
                "export": [
                    "operation": "export/url",
                    "input": ["convert"]
                ]
            ]
        ]
        
        let data = try await request(endpoint: "/jobs", method: "POST", body: body)
        let response = try JSONDecoder().decode(JobResponse.self, from: data)
        return response.data.id
    }
    
    private func waitForJob(jobId: String, timeout: TimeInterval = 300) async throws -> CloudConvertJob {
        log("⏳ Waiting for job: \(jobId)")
        let startTime = Date()
        var pollCount = 0
        
        while Date().timeIntervalSince(startTime) < timeout {
            pollCount += 1
            let data = try await request(endpoint: "/jobs/\(jobId)", method: "GET")
            let response = try JSONDecoder().decode(JobResponse.self, from: data)
            
            let elapsed = Int(Date().timeIntervalSince(startTime))
            log("   Poll #\(pollCount): status=\(response.data.status) (\(elapsed)s)")
            
            switch response.data.status {
            case "finished":
                log("✅ Job completed in \(elapsed)s")
                return response.data
            case "error":
                let errorMsg = response.data.tasks?.first(where: { $0.status == "error" })?.message ?? "Unknown error"
                log("❌ Job failed: \(errorMsg)")
                throw CloudConvertError.jobFailed(errorMsg)
            default:
                try await Task.sleep(for: .seconds(2))
            }
        }
        
        log("❌ Job timeout after \(Int(timeout))s")
        throw CloudConvertError.timeout
    }
    
    private func downloadResult(from job: CloudConvertJob) async throws -> Data {
        guard let exportTask = job.tasks?.first(where: { $0.operation == "export/url" }),
              let file = exportTask.result?.files?.first,
              let urlString = file.url,
              let url = URL(string: urlString) else {
            log("❌ No download URL found")
            throw CloudConvertError.noData
        }
        
        log("📥 Downloading: \(file.filename)")
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    private func request(endpoint: String, method: String, body: [String: Any]? = nil) async throws -> Data {
        guard let url = URL(string: baseURL + endpoint) else {
            throw CloudConvertError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        log("🌐 \(method) \(endpoint)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CloudConvertError.noData
        }
        
        log("   Response: HTTP \(httpResponse.statusCode)")
        
        if !(200...299 ~= httpResponse.statusCode) {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                log("❌ API Error: \(errorResponse.message)")
                throw CloudConvertError.jobFailed(errorResponse.message)
            }
            if let responseString = String(data: data, encoding: .utf8) {
                log("❌ Response body: \(responseString.prefix(500))")
            }
            throw CloudConvertError.jobFailed("HTTP \(httpResponse.statusCode)")
        }
        
        return data
    }
    
    private func log(_ message: String) {
        #if DEBUG
        print("[CloudConvert] \(message)")
        #endif
    }
}

private struct JobResponse: Codable {
    let data: CloudConvertJob
}

private struct UploadTaskResponse: Codable {
    let data: UploadTask
}

private struct UploadTask: Codable {
    let id: String
    let result: UploadResult
    
    struct UploadResult: Codable {
        let form: FormData
    }
    
    struct FormData: Codable {
        let url: String
        let parameters: [String: String]
    }
}

private struct TaskUploadResponse: Codable {
    let data: TaskData
    
    struct TaskData: Codable {
        let id: String
        let result: TaskResult?
        
        struct TaskResult: Codable {
            let form: TaskUploadInfo?
        }
    }
}

private struct TaskUploadInfo: Codable {
    let url: String
    let parameters: [String: String]
}

private struct ErrorResponse: Codable {
    let message: String
}
