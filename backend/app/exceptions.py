"""业务异常 + 统一错误码。"""


class AppError(Exception):
    """业务异常基类。"""
    code: str = "INTERNAL_ERROR"
    status_code: int = 500
    message: str = "服务器内部错误"

    def __init__(self, message: str | None = None, detail: dict | None = None):
        self.message = message or self.message
        self.detail = detail
        super().__init__(self.message)


class NotFoundError(AppError):
    code = "NOT_FOUND"
    status_code = 404
    message = "资源不存在"


class ValidationError(AppError):
    code = "VALIDATION_ERROR"
    status_code = 422
    message = "参数校验失败"


class LLMError(AppError):
    code = "LLM_ERROR"
    status_code = 502
    message = "AI 服务暂时不可用"


class UpdateError(AppError):
    code = "UPDATE_ERROR"
    status_code = 500
    message = "更新失败"
