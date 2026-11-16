package com.capitulo0.backend.recommendation;

import com.capitulo0.backend.auth.model.AuthenticatedFirebaseUser;
import com.capitulo0.backend.auth.service.*;
import com.capitulo0.backend.user.service.UserService;
import com.capitulo0.backend.user.entity.User;
import com.capitulo0.backend.common.exception.ApiExceptionHandler;
import org.junit.jupiter.api.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.*;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import java.util.List;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class RecommendationEndpointTests {
    RecommendationService recommendations=mock(RecommendationService.class);
    UserService users=mock(UserService.class);
    MockMvc mvc=MockMvcBuilders.standaloneSetup(
        new RecommendationController(new CurrentUserService(users),recommendations))
        .setControllerAdvice(new ApiExceptionHandler()).build();
    @AfterEach void clearIdentity() { SecurityContextHolder.clearContext(); }
    void login(String uid,long id) {
        var identity=new AuthenticatedFirebaseUser(uid,null,"Fixture",true);
        SecurityContextHolder.getContext().setAuthentication(
            new UsernamePasswordAuthenticationToken(identity,null,List.of()));
        var user=mock(User.class); when(user.getId()).thenReturn(id);
        when(users.requireByFirebaseUid(uid)).thenReturn(user);
    }
    @Test void noVerifiedIdentityIsUnauthorizedForNormalAndAi() throws Exception {
        mvc.perform(get("/api/me/recommendations")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/me/recommendations/gemini").contentType("application/json")
            .content("{\"candidateSetId\":\"00000000-0000-0000-0000-000000000001\"}"))
            .andExpect(status().isUnauthorized());
        verifyNoInteractions(recommendations);
    }
    @Test void endpointsResolveOwnerFromVerifiedPrincipalIgnoringQueryImpersonation() throws Exception {
        login("uid-A",1L);
        when(recommendations.recommendations(1L)).thenReturn(new Recommendations.Result(
            "00000000-0000-0000-0000-000000000001",false,List.of(),"NORMAL","Exploración general"));
        mvc.perform(get("/api/me/recommendations").param("userId","999"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.personalized").value(false));
        verify(recommendations).recommendations(1L);
        mvc.perform(post("/api/me/recommendations/gemini").contentType("application/json")
            .content("{\"candidateSetId\":\"00000000-0000-0000-0000-000000000001\"}"))
            .andExpect(status().isOk());
        verify(recommendations).enrich(1L,"00000000-0000-0000-0000-000000000001");
    }
    @Test void malformedOrExcessiveCandidateSetIsRejectedBeforeProvider() throws Exception {
        login("uid-A",1L);
        for(String body:List.of("{}","{\"candidateSetId\":\"invented\"}","{\"candidateSetId\":\""+"x".repeat(5000)+"\"}")) {
            mvc.perform(post("/api/me/recommendations/gemini").contentType("application/json").content(body))
                .andExpect(status().isBadRequest());
        }
        verifyNoInteractions(recommendations);
    }
}
