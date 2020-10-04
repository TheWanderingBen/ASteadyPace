using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(CharacterController))]
public class SimpleCharacterControllerController : MonoBehaviour
{
    [SerializeField] float movementSpeed = 10f;
    [SerializeField] float movementSprintAddition = 0.1f;
    [SerializeField] Vector2 rotationSpeed = new Vector2(10f, 10f);
    [SerializeField] float jumpHeight = 10f;
    [SerializeField] float gravity = -9.81f;
    [SerializeField] InputActionReference inputActionMove, inputActionLook, inputActionJump, inputActionRun;
    [SerializeField] Transform cameraTransform;
        
    CharacterController characterController;
    float xRotation;
    float yVelocity;
    
    void Awake()
    {
        characterController = GetComponent<CharacterController>();
    }
    
    void Start()
    {
#if UNITY_EDITOR
        Cursor.visible = false;
#endif
        Cursor.lockState = CursorLockMode.Locked;
    }

    void Update()
    {
        //player horizontal movement
        Vector2 moveInput = inputActionMove.action.ReadValue<Vector2>();
        Vector3 moveDirectionForward = transform.forward * moveInput.y;
        Vector3 moveDirectionSide = transform.right * moveInput.x;
        Vector3 moveDirection = (moveDirectionForward + moveDirectionSide).normalized;
        float movementMultiplier = inputActionRun.action.ReadValue<float>() * movementSprintAddition;
        Vector3 moveDistance = movementSpeed * (movementMultiplier + 1) * Time.deltaTime * moveDirection;
        
        //jump and gravity
        if (characterController.isGrounded)
        {
            yVelocity = inputActionJump.action.ReadValue<float>() * jumpHeight;
        }
        else
        {
            yVelocity += gravity * Time.deltaTime;
        }
        moveDistance.y += yVelocity;
        
        characterController.Move(moveDistance); //move character

        //player rotation
        Vector2 rotateInput = inputActionLook.action.ReadValue<Vector2>() * rotationSpeed * Time.deltaTime;
        transform.Rotate(Vector3.up * rotateInput.x);
        xRotation -= rotateInput.y;
        xRotation = Mathf.Clamp(xRotation, -89f, 89f);
        
        cameraTransform.localRotation = Quaternion.Euler(xRotation, 0f, 0f); //rotate character
    }
}
