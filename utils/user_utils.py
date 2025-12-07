def user_is_img(user):
    role = getattr(user, "role", None)
    if role:
        return getattr(role, "title", "") == "img"
    return False


def user_is_admin(user):
    role = getattr(user, "role", None)
    if role:
        return getattr(role, "title", "") == "admin"
    return False
